extends Node

export (int, 360) var direction
export (float) var speed

var current_velocity # Used to remove the previous vel vec.
var my_object_vector_index = null


func _calc_velocity():
	return Vector2.UP.rotated(deg2rad(direction)) * speed


func _on_ConveyorBelt_body_entered(body):
	current_velocity = _calc_velocity()
	body.on_object_vectors.append(current_velocity)


func _on_ConveyorBelt_body_exited(body):
	body.on_object_vectors.erase(current_velocity)
