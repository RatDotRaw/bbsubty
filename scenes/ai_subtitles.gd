extends Control

@export var listener: AMQPTopicListener
@onready var label: RichTextLabel = %RichTextLabel
@onready var text_advance_stream_player: AudioStreamPlayer = %TextAdvanceStreamPlayer

var json = JSON.new()
var bbcode_regex = RegEx.new()
var emotion_regex := RegEx.new()
var text_timer: Timer = Timer.new() # timer for visible character

#var displayed_text: String = "" # new text will be appended here, and then put onto label. Preventing weird behavior.
var current_emotion: String = "neutral"
var current_string_index: int = 0
var is_response_done: bool = true

func _ready() -> void:
	assert(listener, "listener not assigned in editor")

	# compile regexes once
	bbcode_regex.compile("<(.*?)>(.*?)</\\1>")
	emotion_regex.compile("\\[{2}(.+?)\\]{2}")

	# setup timer
	text_timer.one_shot = false
	add_child(text_timer)
	text_timer.timeout.connect(_reveal_single_character)
	label.visible_ratio = 0
	_start_text_timer()

	# connectin signals
	listener.MessageReceived.connect(_on_message_received)

func _on_message_received(topic: String, message: String) -> void:
	var parse_error := json.parse(message)
	if parse_error != OK:
		push_error("Failed to parse JSON message: %s" % message)
		return

	var msg: Variant = json.data

	# Type check
	if not msg is Dictionary:
		push_error("Expected dictionary, got: %s" % typeof(msg))
		return

	# Check for success flag
	if not msg.get("success", false):
		return

	# Handle stream end
	if msg.get("done", false) == true:
		is_response_done = true
		print("label text:", label.text)
		return

	# Handle stream start (first chunk of NEW message)
	# Only reset if we were done and now getting new content
	if is_response_done and msg.get("done", true) == false:
		_reset_label()
		is_response_done = false

	# Process content
	var result = msg.get("result")
	if result and result is Dictionary:
		var content = result.get("content", "")
		if content:
			_append_text(content)

func _append_text(text: String) -> void:
	text = _process_bbcode(text)
	text = _process_emotions(text)
	
	label.text += text # can't use append_text, LLM might be unpredictable
	_start_text_timer()

func _reset_label() -> void:
	current_string_index = 0
	label.visible_characters = 0
	label.text = ""

#region dialog box effects
func _start_text_timer() -> void:
	text_timer.wait_time = SettingsManager.text_visible_character_speed
	if not text_timer.is_stopped():
		return  # Already running
	text_timer.start()

func _reveal_single_character() -> void:
	# Get the actual number of displayable characters (ignoring BBCode tags)
	var total_chars = label.get_total_character_count()
	
	if label.visible_characters < total_chars:
		# Increment by 1 (or 2 if you want it faster)
		label.visible_characters += 1 

		# Sound effects logic
		if SettingsManager.play_during_playing:
			if label.visible_characters % SettingsManager.sfx_per_characters == 0:
				text_advance_stream_player.play()
		elif not text_advance_stream_player.playing:
			text_advance_stream_player.play()
	else:
		text_timer.stop()
		print("Text fully revealed, stopping timer.", label.get_parsed_text().length(), " ", current_string_index)
#endregion

#region text filtering
func _process_bbcode(xml_string: String) -> String:
	if SettingsManager.renderBBCode:
		# replace xml with [tag]content[/tag]
		var bbcode_string = bbcode_regex.sub(xml_string, "[$1]$2[/$1]", true) #"[$1]$2[/$1]", true)
		return bbcode_string
	else: # remove tags
		var bbcode_string = bbcode_regex.sub(xml_string, "$2", true) #"[$1]$2[/$1]", true)
		return bbcode_string

func _process_emotions(xml_string: String) -> String:
	if SettingsManager.renderEmotions:
		# extract emotion before removing it
		var match = emotion_regex.search(xml_string)
		if match:
			current_emotion = match.get_string(1)
	return emotion_regex.sub(xml_string, "", true) #"[$1]", true)
#endregion
