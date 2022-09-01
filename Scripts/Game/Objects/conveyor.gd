extends Node

export (Vector2) var velocity

var accepted_classes = [Player]
var accepted_parent_classes = [Penguin]


func _on_ConveyorBelt_body_entered(body):
	for accepted_class in accepted_classes:
		if body is accepted_class:
			body.on_object_vectors.append(velocity)
	for accepted_parent_class in accepted_parent_classes:
		if body.get_parent() is accepted_parent_class:
			body.get_parent().on_object_vectors.append(velocity)


func _on_ConveyorBelt_body_exited(body):
	for accepted_class in accepted_classes:
		if body is accepted_class:
			body.on_object_vectors.erase(velocity)
	for accepted_parent_class in accepted_parent_classes:
		if body.get_parent() is accepted_parent_class:
			body.get_parent().on_object_vectors.erase(velocity)
