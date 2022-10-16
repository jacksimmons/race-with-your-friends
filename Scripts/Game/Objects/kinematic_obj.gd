extends Node2D

onready var body: KinematicBody2D = $KinematicBody2D
var velocity := Vector2.ZERO
var dead = false


func _physics_process(delta):
	if !dead:
		_handle_velocity()


func _handle_velocity():
	var col: KinematicCollision2D = body.move_and_collide(velocity, false)
	if col:
		_handle_collision(col)


func _handle_collision(col):
	velocity += col.collider_velocity


func die():
	dead = true
	body.queue_free()



