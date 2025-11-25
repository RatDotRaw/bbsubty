@tool
extends RichTextEffectBase
class_name RichTextCuss

# name of effect
const bbcode = "cuss"

const VOWELS := "aeiouAEIOU"
const CUSS_CHARS := "#@*!$%&£€"
const IGNORE := " !?.,;\""

func _process_custom_fx(char_fx: CharFXTransform) -> bool:
	var character = get_char(char_fx)
	
	# ignore cases
	if char_fx.relative_index == 0:
		return true
	if character in IGNORE:
		return true
	
	var new_char = CUSS_CHARS[(rand_anim(char_fx, 5, len(CUSS_CHARS)))]
	if character in VOWELS:
		set_char(char_fx, new_char)
		char_fx.color = Color(255, 0, 0, 1)
	else:
		# sometimes censor other letters
		if rand_anim(char_fx, (0.1 + (char_fx.glyph_index *0.0005))) > 0.90:
			set_char(char_fx, new_char)
			char_fx.color = Color(255, 0, 0, 1)
	return true
