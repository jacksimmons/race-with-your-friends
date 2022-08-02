extends Button

const BrushMode = preload("res://Script/Enum/BrushMode.gd")

onready var core = $"/root/Editor/Viewports/Drawing/Painting"


func _on_None_pressed():
	core._on_button_pressed(BrushMode.BrushMode.NONE)

func _on_Brush_pressed():
	core._on_button_pressed(BrushMode.BrushMode.BRUSH)
	
func _on_Rubber_pressed():
	print("HI")
	core._on_button_pressed(BrushMode.BrushMode.RUBBER)
	
func _on_Bucket_pressed():
	core._on_button_pressed(BrushMode.BrushMode.BUCKET)
