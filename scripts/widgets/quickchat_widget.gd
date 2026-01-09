extends Control

@onready var clear_field_button: Button = %ClearFieldButton
@onready var send_message_button: Button = %SendMessageButton
@onready var routing_key_line_edit: LineEdit = %RoutingKeyLineEdit
@onready var role_key_line_edit: LineEdit = %RoleKeyLineEdit
@onready var message_content_text_edit: TextEdit = %MessageContentTextEdit


func _on_send_message_button_pressed() -> void:
	var payload: Dictionary = {
		"method": "chatcompletion",
		"replyTo": ["testchannel"],
		"params": {
			"content": message_content_text_edit.text,
			"role": role_key_line_edit.text
		}
	}
	var payload_json := JSON.stringify(payload)
	
	print("sending message to AmqpSimplepublisher")
	await AmqpSimplePublisher.PublishMessage(
		"nixi_topic",
		routing_key_line_edit.text if routing_key_line_edit.text != "" else "ai.chatcompletion",
		payload_json
	)

func _on_clear_field_button_pressed() -> void:
	message_content_text_edit.text = ""
