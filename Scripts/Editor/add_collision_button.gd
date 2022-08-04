extends Button

onready var shape = $"/root/Editor/Canvas/Shape"
var node: Node2D

# true: start, false: end
var starting_collision_drawing: bool


func _on_Button_pressed():
	if starting_collision_drawing:
		shape.drawing = true
		shape.node = node
		self.queue_free()
	else:
		shape.drawing = false
		self.queue_free()
