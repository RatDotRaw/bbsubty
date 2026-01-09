extends Node


#region rabbit
@onready var connected_rabbit: bool = false # doesn't do anything currently

var rabbit_default_routing_key: String = "ai.chatcompletion"

var rabbit_username: String:
	get:
		return rabbit_username
	set(val):
		if val:
			AmqpConn.Username = val
			rabbit_username = val
var rabbit_password: String:
	get:
		return rabbit_password
	set(val):
		if val:
			AmqpConn.Password = val
			rabbit_password = val
var rabbit_host: String:
	get:
		return rabbit_host
	set(val):
		if val:
			AmqpConn.Host = val
			rabbit_host = val
var rabbit_port: int:
	get:
		return rabbit_port
	set(val):
		if val and val != 0:
			AmqpConn.Port = val
			rabbit_port = val
var rabbit_virtualHost: String:
	get:
		return rabbit_virtualHost
	set(val):
		if val:
			AmqpConn.VirtualHost = val
			rabbit_virtualHost = val
#endregion

#region text_renderer

var text_visible_character_speed: float = 0.01
var renderEmotions: bool = true
var renderBBCode: bool = true

var play_during_playing: bool = true # allow next sound effect to be played while previous is still playing
var sfx_per_characters: int = 20 # play sound effect per X amount of characters

#endregion
