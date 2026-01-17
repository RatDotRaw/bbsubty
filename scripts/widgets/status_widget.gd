extends MarginContainer

@onready var rabbit_connection_status_label: Label = %RabbitConnectionStatusLabel
@onready var rabbit_connect_button: Button = %RabbitConnectButton

var was_rabbit_ever_connected: bool = false

func _ready() -> void:
	AmqpConn.ConnectionAlive.connect(_update_connect_button)
	AmqpConn.ConnectionAlive.connect(update_rabbit_connection_status_label)

func update_rabbit_connection_status_label(is_rabbit_connected: bool) -> void:
	rabbit_connection_status_label.text = "connected" if is_rabbit_connected else "offline"

#region connect button
func _on_rabbit_connect_button_pressed() -> void:
	print("current rabbit status:", SettingsManager.connected_rabbit)
	if not AmqpConn.IsRabbitConnected:
		print("Attempting to connect to rabbit")
		AmqpConn.Connect()
	else:
		print("Disconnecting from rabbit")

func _update_connect_button(is_rabbit_connected: bool) -> void:
	if is_rabbit_connected:
		was_rabbit_ever_connected = true
	
	rabbit_connect_button.text = "Disconnect from rabbit" if is_rabbit_connected else "Connect to rabbit"
	if was_rabbit_ever_connected && not is_rabbit_connected:
		rabbit_connect_button.text = "Reconnect to rabbit"
#endregion
