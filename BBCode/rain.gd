@tool
extends RichTextEffectBase
class_name RichTextRain

# name of effect
const bbcode = "rain"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var cycle_time = char_fx.env.get("speed", 2.0)  # How many seconds for full cycle
	var max_drop = char_fx.env.get("drop", 5.0)
	var wobble_amount = char_fx.env.get("wobble", 1.0)
	
	var time = char_fx.elapsed_time
	var char_index = char_fx.glyph_index
	
	# Offset each character by its index to create a cascading effect
	var phase_offset = char_index * 0.22
	
	# Create a falling motion that resets (like rain cycles)
	var position = fmod(time + phase_offset, cycle_time) / cycle_time
	
	# Calculate y-offset: start from top (negative y) and move down
	var y_offset = position * max_drop
	
	# Optional: Add a slight wobble
	var wobble = sin(time * 3 + char_index) * 0.5
	
	# Apply the offset
	char_fx.offset.y = y_offset - 1
	char_fx.offset.x = wobble
	
	char_fx.color.a = lerp(char_fx.color.a, 0.0, y_offset/max_drop-0.1)
	
	# Optional: Fade out as characters fall
	# char_fx.color.a = 1.0 - position * 0.7
	
	return true
