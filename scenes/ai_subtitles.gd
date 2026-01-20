extends Control



# TODO: Create a buffer of incomming chunks (messages)
#       Check and split the chunks into individual sentences and emotions
#       if not already, start text rendering.




@export var listener: AMQPTopicListener
@onready var label: RichTextLabel = %RichTextLabel
@onready var text_advance_stream_player: AudioStreamPlayer = %TextAdvanceStreamPlayer

signal emotion_changed(emotion: String) 

var json = JSON.new()
var sentence_regex = RegEx.new()
var bbcode_regex = RegEx.new()
var emotion_regex := RegEx.new()
var text_timer: Timer = Timer.new() # timer for visible character
var sentence_pause_timer: Timer = Timer.new()  # For sentence pauses

var current_emotion: String = "neutral"
var is_response_done: bool = true
#var sentence_queue: Array[Dictionary] = []  # Stores {text: String, current_emotion: String, has_new_emote: bool}
var sentence_queue: Array[Dictionary] = [
	{
		"text": "I have a bad feeling about this place.",
		"current_emotion": "nervous",
		"clear_label": true
	},
	{
		"text": "Still, we should keep moving forward.",
		"current_emotion": "determined",
	},
	{
		"text": "Nothing has happened yet… maybe we're safe.",
		"current_emotion": "uncertain",
	},
	{
		"text": "Wait—did you hear that?",
		"current_emotion": "alert",
	}
]

var _is_playing: bool = false  # tracks if we're actively playing a sentence

func _ready() -> void:
	assert(listener, "listener not assigned in editor")

	# compile regexes once
	sentence_regex.compile("[.!?](?:\\s|$)")
	bbcode_regex.compile("<(.*?)>(.*?)</\\1>")
	emotion_regex.compile("\\[{2}(.+?)\\]{2}")

	# setup timer
	add_child(text_timer)
	text_timer.one_shot = false
	text_timer.timeout.connect(_reveal_single_character)
	add_child(sentence_pause_timer)
	sentence_pause_timer.one_shot = true
	sentence_pause_timer.timeout.connect(_play_next_sentence)
	
	label.visible_ratio = 0
	_start_text_timer()

	# connectin signals
	listener.MessageReceived.connect(_on_message_received)

func _reset_label() -> void:
	label.visible_characters = 0
	label.text = ""
	sentence_queue.clear()
	_is_playing = false
	current_emotion = "neutral"
	emit_signal("emotion_changed", "neutral")

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
	elif not msg.get("success", false):
		return
	
	# Handle stream end
	if msg.get("done", false) == true:
		is_response_done = true
	# Handle stream start (first chunk of NEW message)
	# Only reset if we were done and now getting new content
	elif is_response_done and msg.get("done", true) == false:
		is_response_done = false
		_reset_label()

	# Process content
	var result = msg.get("result")
	if result and result is Dictionary:
		var content = result.get("content", "")
		if content:
			_process_and_append(content, is_response_done)

var text_buffer: String = ""
func _process_and_append(text: String, done) -> void:
	text_buffer += text
	
	while true:
		var match = sentence_regex.search(text_buffer)
		if not match:
			break
		else:
			var end_pos: int = match.get_end()
			var sentence: String = text_buffer.substr(0, match.get_end()).strip_edges()
			text_buffer = text_buffer.substr(end_pos, -1)
			
			print("split string:", sentence)
			
			# process test and capture emotion positions
			sentence = _process_bbcode(sentence)
			sentence = _process_emotions(sentence)
			
			sentence_queue.append({
				"text": sentence,
				"current_emotion": current_emotion,
			})
			_start_text_timer()
	if done:
		if text_buffer.length() > 0:
			print("flushing buffer:", text_buffer)
			
			var sentence = text_buffer.strip_edges()
			sentence = _process_bbcode(sentence)
			sentence = _process_emotions(sentence)
			
			sentence_queue.append({
				"text": sentence,
				"current_emotion": current_emotion,
				"clear_label": true
			})
			
			text_buffer = ""
			_start_text_timer()
		elif sentence_queue.size():
			sentence_queue[sentence_queue.size() - 1]["clear_label"] = true

#region dialog box effects
func _start_text_timer() -> void:
	sentence_pause_timer.stop() # stop for if it was running
	if text_timer.is_stopped():
		text_timer.start()
	text_timer.wait_time = SettingsManager.text_visible_character_speed

## callback for text_timer, when next character needs to be revealed
func _reveal_single_character() -> void:
	var total_chars = label.get_total_character_count()
	if label.visible_characters < total_chars:
		label.visible_characters += 1 
		
		# Sound effects logic
		if SettingsManager.play_during_playing:
			if label.visible_characters % SettingsManager.sfx_per_characters == 0:
				text_advance_stream_player.play()
		elif not text_advance_stream_player.playing:
			text_advance_stream_player.play()
	else:
		text_timer.stop()
		_pause_after_sentence()

## shortly wait before showing next sentence
func _pause_after_sentence() -> void:
	var should_pause =  true
	# check if we should pause
	if SettingsManager.pause_on_emotion_change_only:
		if not sentence_queue.is_empty():
			var next_emotion = sentence_queue[0].current_emotion
			should_pause = (next_emotion != current_emotion)
		else:
			should_pause = false
	# start sentence_pause_timer
	if should_pause and sentence_queue.size()>0:
		sentence_pause_timer.wait_time = SettingsManager.sentence_pause_duration
		sentence_pause_timer.start()
	else:
		_play_next_sentence()

## callback for sentence_pause_timer, display next sentece and emit new emotion.
func _play_next_sentence() -> void:
	if sentence_queue.is_empty():
		_is_playing = false
		return
	
	_is_playing = true
	var chunk = sentence_queue.pop_front()
	
	# Update emotion if needed
	var new_emotion: String = chunk.get("current_emotion", "neutral")
	if new_emotion != current_emotion:
		current_emotion = new_emotion
		emit_signal("emotion_changed", current_emotion)
	
	# Set sentence as label text (fresh start)
	if chunk.get("clear_label", false):
		label.text = chunk.text
		label.visible_characters = 0
	else:
		label.text += chunk.text
	
	# Start revealing this sentence
	_start_text_timer()
#endregion

#region text filtering
func _process_bbcode(xml_string: String) -> String:
	if SettingsManager.renderBBCode:
		# replace xml with [tag]content[/tag]
		var bbcode_string = bbcode_regex.sub(xml_string, "[$1]$2[/$1]", true)
		return bbcode_string
	else: # remove tags
		var bbcode_string = bbcode_regex.sub(xml_string, "$2", true)
		return bbcode_string

func _process_emotions(xml_string: String) -> String:
	if SettingsManager.renderEmotions:
		# extract emotion before removing it
		var match = emotion_regex.search(xml_string)
		if match:
			current_emotion = match.get_string(1)
	return emotion_regex.sub(xml_string, "", true) #"[$1]", true)
#endregion
