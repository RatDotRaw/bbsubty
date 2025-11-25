@tool
extends RichTextEffect
class_name RichTextEffectBase

# Just a class with some nice to have logic

var ts = TextServerManager.get_primary_interface()

func get_text_server():
	return TextServerManager.get_primary_interface()

func sinw():
	pass

func get_char(char_fx: CharFXTransform) -> String:
	var font = char_fx.font
	var index = char_fx.glyph_index
	return char(ts.font_get_char_from_glyph_index(font, 16, index))

func set_char(char_fx: CharFXTransform, value: String):
	char_fx.glyph_index = get_text_server().font_get_glyph_index(char_fx.font, 16, value.unicode_at(0), 0)

func rand_anim(char_fx: CharFXTransform, anim_speed:float = 1, total: float = 1):
	return fmod(char_fx.elapsed_time * anim_speed + (char_fx.glyph_index * 0.25 + char_fx.relative_index *0.5), total)
