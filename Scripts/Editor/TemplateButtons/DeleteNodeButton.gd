extends Node

onready var editor = $"/root/Editor"
onready var shape = $"/root/Editor/Canvas/Shape"

var node: Node


func _on_Button_pressed():
	editor.current_node = node.get_parent()
	node.get_parent().remove_child(node)
	node.queue_free()

	shape.points = []
	shape.stop_drawing()

	editor.refresh_nodes()
