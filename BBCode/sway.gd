@tool
extends RichTextEffectBase
class_name RichTextSway

# name of effect
const bbcode = "sway"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var time = char_fx.elapsed_time
	# get parameters
	var freq = char_fx.env.get("freq", 0.1) * (2*PI)
	var amp = char_fx.env.get("amp", 2)
	
	var h_offset = sin(time * freq) * amp
	var v_offset = cos((time * (freq+0.5))) * amp  # Added a phase shift (1.5)
	char_fx.offset = Vector2(h_offset, v_offset)
	
	return true
	
