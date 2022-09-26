extends Label


var font: DynamicFont
var starting_rect: Rect2


func _ready():
	font = get_font("font", "Label")
	starting_rect = get_rect()


func _process(delta):
	if font.get_string_size(text).x > starting_rect.size.x:
		font.size -= 1
		add_font_override("font", font)
