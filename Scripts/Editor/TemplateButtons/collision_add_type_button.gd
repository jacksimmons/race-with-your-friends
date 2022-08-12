extends Button

onready var editor = $"/root/Editor"
var node: Node
var col_name: String
var col_type: String


func _on_Button_pressed():
	var col = Area2D.new()
	col.name = col_name
	node.add_child(col)
	
	# Required for it to be saved under PackedScene
	# Because this node didn't exist on startup.
	col.owner = editor.project_root
	
	if col_type == "CollisionMaterial":
		editor.mat_names.erase(col_name)
	elif col_type == "TriggerType":
		editor.trig_names.erase(col_name)
	editor.refresh_nodes()
