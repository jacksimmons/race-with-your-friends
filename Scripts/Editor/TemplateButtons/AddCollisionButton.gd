extends Button

onready var editor = $"/root/Editor"
onready var shape = $"/root/Editor/Canvas/Shape"
var node: Node2D

# true: start, false: end
var starting_collision_drawing: bool


func _on_Button_pressed():
	if starting_collision_drawing:
		shape.drawing = true
		shape.node = node
	else:
		shape.stop_drawing()

	editor.refresh_nodes()
