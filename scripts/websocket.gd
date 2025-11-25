extends Node

# BBsubty stands for:
# - BB from BBcode
# - sub because it subtitle
# - t for text
# - y just because

var websocket = WebSocketPeer.new()
var url = "ws://localhost:4269"  # Example WebSocket server
var connection_status = WebSocketPeer.STATE_CLOSED

@onready var rich_text_label: RichTextLabel = $RichTextLabel

func _ready():
	print("Connecting to WebSocket server...")
	var error = websocket.connect_to_url(url)
	if error != OK:
		print("Unable to connect to WebSocket server: ", error)
		return

func _process(delta):
	# Poll the WebSocket for updates
	websocket.poll()
	
	# Check if the connection state has changed
	var new_status = websocket.get_ready_state()
	if new_status != connection_status:
		connection_status = new_status
		match connection_status:
			WebSocketPeer.STATE_OPEN:
				print("Connection established!")
				# Optionally send a message after connecting
				websocket.send_text("Hello WebSocket Server!")
			WebSocketPeer.STATE_CLOSING:
				print("Connection closing...")
			WebSocketPeer.STATE_CLOSED:
				var code = websocket.get_close_code()
				var reason = websocket.get_close_reason()
				print("Connection closed. Code: %d, Reason: %s" % [code, reason])
	
	# Check if there are incoming messages
	while websocket.get_available_packet_count() > 0:
		var packet = websocket.get_packet()
		var message = packet.get_string_from_utf8()
		print("Received message: ", message)

func _exit_tree():
	# Clean up the connection when the scene exits
	if connection_status == WebSocketPeer.STATE_OPEN:
		websocket.close()
