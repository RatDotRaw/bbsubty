extends Control

@onready var rabbit_connect_button: Button = %RabbitConnectButton

var was_rabbit_ever_connected: bool = false

func _ready() -> void:
	AmqpConn.ConnectionAlive.connect(_update_nodes)

func _update_nodes(is_rabbit_connected: bool) -> void:
	if is_rabbit_connected:
		was_rabbit_ever_connected = true
	
	rabbit_connect_button.text = "Disconnect from rabbit" if is_rabbit_connected else "Connect to rabbit"
	if was_rabbit_ever_connected && not is_rabbit_connected:
		rabbit_connect_button.text = "Reconnect to rabbit"
	
func _on_rabbit_connect_button_pressed() -> void:
	if not AmqpConn.IsRabbitConnected:
		print("Attempting to connect to rabbit")
		AmqpConn.ConnectToRabbit()
	else:
		print("Disconnecting from rabbit")
