extends Area2D


func _on_body_entered(body):
	if body is Player:
		get_parent()._on_layer_entered(name)
