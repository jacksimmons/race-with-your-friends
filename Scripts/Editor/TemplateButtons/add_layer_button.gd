extends "res://Scripts/Editor/TemplateButtons/AddArea2DButton.gd"

func _after_button():
	editor.highest_layer_no = int(obj_name)
