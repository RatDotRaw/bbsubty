@tool
extends RichTextEffectBase
class_name RichTextJit

# name of effect
const bbcode = "jit"

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var amount = char_fx.env.get("amount", 1)
	char_fx.offset.x = randf_range(-amount, amount)
	char_fx.offset.y = randf_range(-amount, amount)
	return true
