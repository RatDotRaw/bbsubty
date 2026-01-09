extends Control

@export var listener: AMQPTopicListener
@onready var label: RichTextLabel = %RichTextLabel
@onready var text_advance_stream_player: AudioStreamPlayer = %TextAdvanceStreamPlayer

var json = JSON.new()
var regex = RegEx.new()
var text_timer: Timer = Timer.new() # timer for visible character

var current_string_index: int = 0

func _ready() -> void:
	assert(listener, "listener not assigned in editor")
	# setup timer
	text_timer.one_shot = false
	add_child(text_timer)
	text_timer.timeout.connect(_reveal_single_character)
	_start_text_timer()
	
	# connectin signals
	listener.MessageReceived.connect(_on_message_received)



func _on_message_received(topic: String, message: String):
	var e: Error = json.parse(message)
	if not e==OK:
		return
	
	print("received object:", json.data)
	var msg: Variant = json.data
	if msg.has("success"):
		if msg["success"]:
			var text = msg["result"]["content"]
			# filter text
			text = _process_bbcode(text)
			text = _process_emotions(text)
			# reset shenanigans
			current_string_index = 0
			label.visible_characters = 0
			label.text = text
			
			_start_text_timer()

#region dialog box effects
func _start_text_timer() -> void:
	text_timer.wait_time = SettingsManager.text_visible_character_speed
	text_timer.start()

func _reveal_single_character() -> void:
	if current_string_index < label.get_parsed_text().length():
		current_string_index += 2
		label.visible_characters = current_string_index
		
		# sound effects
		if SettingsManager.play_during_playing:
			if current_string_index % SettingsManager.sfx_per_characters == 0:
				text_advance_stream_player.play()
		elif not text_advance_stream_player.playing:
			text_advance_stream_player.play()
	else:
		text_timer.stop()
		print("Text fully revealed, stopping timer.")
#endregion
#region text filtering
func _process_bbcode(xml_string: String) -> String:
	if SettingsManager.renderBBCode:
		regex.compile("<(.*?)>(.*?)</\\1>")
		# replace xml with [tag]content[/tag]
		var bbcode_string = regex.sub(xml_string, "[$1]$2[/$1]", true) #"[$1]$2[/$1]", true)
		return bbcode_string
	else: # remove tags
		var bbcode_string = regex.sub(xml_string, "$2", true) #"[$1]$2[/$1]", true)
		return bbcode_string

func _process_emotions(xml_string: String) -> String:
	if SettingsManager.renderEmotions:
		regex.compile("\\[{2}(.+?)\\]{2}")
		var bbcode_string = regex.sub(xml_string, "", true) #"[$1]", true)
		return bbcode_string
	else:
		return "neutral"
#endregion

#region pop out window
@onready var window: Window = %PopOutChat
@onready var label_target: Control = %LabelTarget # to keep track for moving label around

func _on_pop_out_button_pressed() -> void:
	pop_out_window()

func pop_out_window() -> void:
	if not window.visible:
		swap_label_nodes()
		window.visible = true

func _on_window_close_requested() -> void:
	swap_label_nodes()
	window.visible = false

func swap_label_nodes() -> void:
	var parent1 := label.get_parent()
	var index1: int = label.get_index()
	var parent2 := label_target.get_parent()
	var index2: int = label_target.get_index()
	
	label.reparent(parent2)
	label_target.reparent(parent1)
	
	parent2.move_child(label, index2)
	parent1.move_child(label_target, index1)
#endregion
