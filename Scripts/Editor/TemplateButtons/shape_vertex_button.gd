extends TextureButton


func _on_Vertex_pressed():
	get_parent()._on_Vertex_pressed(name)
