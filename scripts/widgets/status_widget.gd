extends MarginContainer

@onready var rabbit_connection_status_label: Label = %RabbitConnectionStatusLabel

func _ready() -> void:
	AmqpConn.ConnectionAlive.connect(update_rabbit_connection_status_label)

func update_rabbit_connection_status_label(is_rabbit_connected: bool) -> void:
	rabbit_connection_status_label.text = "connected" if is_rabbit_connected else "offline"
