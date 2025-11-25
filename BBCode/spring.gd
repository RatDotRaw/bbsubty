@tool
extends RichTextEffectBase
class_name RichTextSpring

# name of effect
const bbcode = "spring"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var elapsed_time = char_fx.elapsed_time  # More descriptive than 'time'

	# Get parameters from the environment
	var freq = char_fx.env.get("freq", 1) * (2 * PI)  
	var phase = char_fx.env.get("offset", 5)  # Renamed 'relative_offset' to 'phase_offset', more accurate description
	var amp = char_fx.env.get("amp", 3)  # Renamed 'amp' to 'amplitude'

	# Calculate a character-specific offset based on time and index
	var character_offset = elapsed_time + (char_fx.relative_index * (1000 / phase))

	# Calculate the offset using cosine for a smoother effect
	var x_offset = cos((character_offset * (freq + 0.5))) * amp

	char_fx.offset.x = x_offset

	return true

	
