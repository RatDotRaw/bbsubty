extends Control

@export var listener: AMQPTopicListener
@onready var label: RichTextLabel = $RichTextLabel

func _ready() -> void:
	assert(listener, "listener not assigned in editor")
	
	listener.MessageReceived.connect(_on_message_received)

func _on_message_received(topic: String, message: String):
	# ✅ SAFE: This runs on Godot's main thread thanks to CallDeferred in C#
	label.text = message
