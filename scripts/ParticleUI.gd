extends GPUParticles2D
class_name ParticleUI

enum Alignment { TOP, CENTER, BOTTOM, LEFT, RIGHT }

@export_group("Resize Settings")
@export var resize_x: bool = true
@export var resize_y: bool = true

@export_group("Positioning")
@export var alignment: Alignment = Alignment.CENTER

@onready var parent_control: Control = get_parent() as Control

var density: float = 0.0

func _ready():
	if not parent_control:
		push_warning("Particle system is not a child of a Control node.")
		return

	# Calculate initial density
	var initial_size = parent_control.size
	var area = initial_size.x * initial_size.y
	
	if area > 0:
		density = float(amount) / area
	
	parent_control.resized.connect(_update_particles_to_ui)
	_update_particles_to_ui()

func _update_particles_to_ui():
	if not parent_control or not process_material is ParticleProcessMaterial:
		return

	var ui_size = parent_control.size
	var current_extents = process_material.emission_box_extents
	
	# 1. Handle Conditional Resizing
	var final_width = ui_size.x if resize_x else (current_extents.x * 2.0)
	var final_height = ui_size.y if resize_y else (current_extents.y * 2.0)
	
	# 2. Update Emission Box Extents (extents are half-sizes)
	process_material.emission_box_extents = Vector3(final_width / 2.0, final_height / 2.0, 1)
	
	# 3. Handle Alignment Position
	match alignment:
		Alignment.TOP:
			position = Vector2(ui_size.x / 2.0, 0)
		Alignment.BOTTOM:
			position = Vector2(ui_size.x / 2.0, ui_size.y)
		Alignment.LEFT:
			position = Vector2(0, ui_size.y / 2.0)
		Alignment.RIGHT:
			position = Vector2(ui_size.x, ui_size.y / 2.0)
		Alignment.CENTER:
			position = ui_size / 2.0

	# 4. Maintain Density (only if resizing is enabled for those axes)
	if density > 0:
		var active_area = final_width * final_height
		var new_amount = int(active_area * density)
		if new_amount != amount:
			amount = max(1, new_amount)
