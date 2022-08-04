extends Button

onready var editor = $"/root/Editor"
var node: Node2D


func _on_Button_pressed():
	node.name = $NameEdit.text
	editor.refresh_nodes()
