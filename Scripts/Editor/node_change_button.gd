extends Button

var in_scene: bool
var node: Node

onready var editor = $"/root/Editor"


func _on_Button_pressed():
	editor.current_node = node
	editor.refresh_nodes()
