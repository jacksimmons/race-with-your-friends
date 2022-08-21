extends Button

onready var editor = $"/root/Editor"

var sprite_node: Sprite
var flip_dir: String


func _on_Button_pressed():
	if flip_dir == "h":
		sprite_node.flip_h = !sprite_node.flip_h
	elif flip_dir == "v":
		sprite_node.flip_v = !sprite_node.flip_v

	editor.refresh_nodes()
