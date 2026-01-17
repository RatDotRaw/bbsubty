extends Window
class_name popOutController

@export var is_popped_out: bool = false
@export var popout_button: CheckButton
@export var title_name: String = "Pop-out window"
@export var node: Node ## Node to pop out

@onready var target_swap: Control = Control.new()

func _ready() -> void:
	visible = false
	popout_button.toggled.connect(popout_window)
	
	# setup window
	title = title_name
	close_requested.connect(_window_close_request)
	var window_panel_container := PanelContainer.new()
	window_panel_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	var info_label := Label.new()
	add_child(window_panel_container)
	window_panel_container.add_child(target_swap)
	target_swap.add_child(info_label)
	info_label.text = "Your widget is\nin another castle"

	if is_popped_out:
		_show_popout_window()

#region pop out window logic
func popout_window(toggled_on: bool) -> void:
	if toggled_on:
		_show_popout_window()
	else:
		_window_close_request()

func _show_popout_window() -> void:
		visible = true
		close_requested.connect(_window_close_request)
		swap_nodes(node, target_swap)
		size = node.get_combined_minimum_size()

func _window_close_request() -> void:
	# Stop the button from sending "toggled" signals while we change its state
	popout_button.set_block_signals(true)
	popout_button.button_pressed = false
	popout_button.set_block_signals(false)

	popout_button.button_pressed = false
	swap_nodes(node, target_swap)
	visible = false

func swap_nodes(node1: Node, node2: Node) -> void:
	var parent1 := node1.get_parent()
	var index1: int = node1.get_index()
	var parent2 := node2.get_parent()
	var index2: int = node2.get_index()
	
	node1.reparent(parent2)
	node2.reparent(parent1)
	
	parent2.move_child(node1, index2)
	parent1.move_child(node2, index1)
#endregion
