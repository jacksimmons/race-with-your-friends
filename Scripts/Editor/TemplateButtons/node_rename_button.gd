extends Button

onready var editor = $"/root/Editor"
onready var replacement_name = $"/root/Editor/Canvas/UI/Tabs/ObjectName/TextEdit"

var node: Node2D


func _on_Button_pressed():
	node.name = replacement_name.text
	editor.refresh_nodes()
