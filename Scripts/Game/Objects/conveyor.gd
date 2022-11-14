extends Area2D

var layer = 0
export (float) var speed
export (float, 0, 360) var angle
export (bool) var is_ramp_air
export (bool) var use_custom_speed

var velocity: Vector2

var accepted_classes = [Player]
var accepted_parent_classes = [Routed]

var velocities = {}


func _ready():
	if is_ramp_air:
		angle = get_parent().get_parent().rotation
	velocity = -transform.x.rotated(angle) * speed


func set_layer(new_layer):
	set_collision_mask_bit(31 - layer, 0)
	set_collision_mask_bit(31 - new_layer, 1)
	layer = new_layer


func _get_body(body):
	var the_body: PhysicsBody2D = null
	for accepted_class in accepted_classes:
		if body is accepted_class:
			the_body = body
	if !the_body:
		for accepted_parent_class in accepted_parent_classes:
			if body.get_parent() is accepted_parent_class:
				the_body = body.get_parent()
	return the_body


func _on_ConveyorBelt_body_entered(body):
	var the_body = _get_body(body)

	if the_body:
		if the_body.get_collision_mask_bit(31 - layer):
			if use_custom_speed:
				the_body.on_object_vectors.append(velocity)
			else:
				the_body.paralised = true


func _on_ConveyorBelt_body_exited(body):
	var the_body = _get_body(body)

	if the_body:
		if use_custom_speed:
			the_body.on_object_vectors.erase(velocity)
		else:
			the_body.paralised = false
