extends Window
class_name WindowsBase

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var window_size_label: Label = $CenterContainer/WindowSizeLabel
var label_fade_timer: Timer = Timer.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	window_size_label.visible = false
	label_fade_timer.one_shot = true
	label_fade_timer.wait_time = 5
	
	pass # Replace with function body.
	size_changed.connect(on_size_change)
	close_requested.connect(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func on_size_change():
	animation_player.stop()
	animation_player.play("fade out")
	window_size_label.text = str(size.x) +"x"+ str(size.y)
