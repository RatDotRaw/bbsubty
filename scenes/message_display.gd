extends Control

@export var listener: AMQPTopicListener
@onready var username: Label = $VBoxContainer/Username
@onready var msg_content: Label = $VBoxContainer/MsgContent

func _ready() -> void:
	await get_tree().process_frame
	assert(listener, "listener not assigned in editor:"+ str(get_path()))
	
	listener.MessageReceived.connect(_on_message_received)

func _on_message_received(topic: String, message: String):
	# ✅ SAFE: This runs on Godot's main thread thanks to CallDeferred in C#
	username.text = topic
	msg_content.text = message
