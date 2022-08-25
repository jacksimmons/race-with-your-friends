extends Area2D


func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index, level:int):
	get_parent()._on_layer_entered(level)
