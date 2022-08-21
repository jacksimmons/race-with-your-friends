extends Node

export (Vector2) var velocity


func _on_ConveyorBelt_body_entered(body):
	if body is Player:
		body.on_object_vectors.append(velocity)


func _on_ConveyorBelt_body_exited(body):
	if body is Player:
		if velocity in body.on_object_vectors:
			body.on_object_vectors.erase(velocity)
