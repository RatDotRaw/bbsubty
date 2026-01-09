extends VBoxContainer

@onready var apply_button: Button = %ApplyButton
@onready var url_line_edit: LineEdit = %URLLineEdit
@onready var port_line_edit: LineEdit = %PortLineEdit
@onready var username_line_edit: LineEdit = %UsernameLineEdit
@onready var password_line_edit: LineEdit = %PasswordLineEdit
@onready var virtual_host_line_edit: LineEdit = %VirtualHostLineEdit



func _on_apply_button_pressed() -> void:
	SettingsManager.rabbit_username = username_line_edit.text
	SettingsManager.rabbit_password = password_line_edit.text
	SettingsManager.rabbit_host = url_line_edit.text
	SettingsManager.rabbit_port = int(port_line_edit.text)
	SettingsManager.rabbit_virtualHost = virtual_host_line_edit.text
