extends Node2D

# Time to complete one rotation
export var angular_period: float

var collision = null


func _physics_process(delta):
	if angular_period != 0:
		rotate((delta / angular_period) * 2 * PI)
