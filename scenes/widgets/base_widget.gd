@tool
extends PanelContainer
class_name BaseWidget

@export var widget_name: String = "Widget"

var popout_manager: popOutController = popOutController.new()
@onready var pop_out_btn := CheckButton.new()

@onready var child_content: Node
func _ready() -> void:
	if Engine.is_editor_hint():
		await get_tree().process_frame
	size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	
	# get the target child content
	var temp_child_content: CanvasItem = get_child(0)
	temp_child_content.visible = true
	if Engine.is_editor_hint():
		child_content = temp_child_content.duplicate()
		temp_child_content.visible = false
	else:
		child_content = temp_child_content
		child_content.visible = true
		remove_child(child_content)
	
	# fuck it, we program entire UI
	var panel := VBoxContainer.new()
	add_child(panel)
	
	# construct top bar
	var top_bar_HBox := HBoxContainer.new()
	panel.add_child(top_bar_HBox)
	var title_label := Label.new()
	top_bar_HBox.add_child(pop_out_btn)
	top_bar_HBox.add_child(title_label)
	title_label.text = widget_name
	
	# place child content back
	panel.add_child(child_content)
	
	# setup popout manager and add it.
	popout_manager.popout_button = pop_out_btn
	popout_manager.title_name = widget_name
	popout_manager.node = child_content
	add_child(popout_manager)
