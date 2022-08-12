extends Button

var in_scene: bool
var node: Node

onready var editor = $"/root/Editor"
onready var shape = $"/root/Editor/Canvas/Shape"


func _on_Button_pressed():
	editor.current_node = node
	shape.points = []
	shape.drawing = false
	editor.refresh_nodes()
