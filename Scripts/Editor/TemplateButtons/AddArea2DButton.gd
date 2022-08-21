extends Button

onready var editor = $"/root/Editor"
var node: Node
var obj_name: String


func _after_button():
	# "Abstract" method
	pass


func _on_Button_pressed():
	var obj = Area2D.new()
	obj.name = obj_name
	node.add_child(obj)

	# Required for it to be saved under PackedScene
	# Because this node didn't exist on startup.
	obj.owner = editor.project_root

	_after_button()

	editor.refresh_nodes()
