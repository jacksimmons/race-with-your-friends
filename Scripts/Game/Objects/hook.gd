extends Node2D


onready var grapplables = get_node("/root/Scene/Grapplables")
onready var hook_rope_v: TextureProgress = get_node("HookRope/HookRopeV")
onready var hook_rope_h: TextureProgress = get_node("HookRope/HookRopeH")
onready var hook_end: RigidBody2D = get_node("HookEnd")

var current_target
var speed = 5
var max_length = 1600
var activated = true
var extending = false
var retracting = false


func _ready():
	# Collision (set max contacts to 5)
	hook_end.set_contact_monitor(true)
	hook_end.set_max_contacts_reported(5)

	# Apply Godot physics to begin with
	hook_end.set_use_custom_integrator(false)


func _process(delta):
	if current_target != null:
		print(current_target.name)

		var line_to_target = current_target.position - hook_end.global_position
		var angle = get_angle_to(current_target.position)
		rotation += angle

		if hook_rope_v.value + speed < hook_rope_v.max_value:
			# Extend
			extending = true
			retracting = false
			extend()
		elif hook_rope_v.value + speed == hook_rope_v.max_value:
			hook_rope_v.value = hook_rope_v.max_value
			hook_rope_h.value = hook_rope_h.max_value
		else:
			# Retract; hit the end of the grappling hook
			extending = false
			retracting = true
			retract()


func extend():
	hook_end.position += Vector2(speed, speed)
	hook_rope_v.value += speed
	hook_rope_h.value += speed


func retract():
	activated = false
	if hook_rope_v.value - speed >= hook_rope_v.min_value:
		hook_rope_v.value -= speed
		hook_rope_h.value -= speed
		hook_end.position -= Vector2(speed, speed)
		hook_end.set_use_custom_integrator(false)
	else:
		retracting = false
		hook_rope_v.value = hook_rope_v.min_value
		hook_rope_h.value = hook_rope_h.min_value


func activate():
	hook_end.set_use_custom_integrator(true)
	hook_end.is_sticking = false
	activated = true

	# Simple Djkstra's
	var shortest_path = INF
	var shortest_path_target
	for target in grapplables.get_children():
		if (hook_end.global_position - target.global_position).length() < shortest_path:
			shortest_path_target = target

	var line_to_target = shortest_path_target.global_position - hook_end.global_position
	if !line_to_target.length() > max_length:
		current_target = shortest_path_target

	print(shortest_path_target.global_position)


func _on_Hook_body_entered(body):
	# Stick
	hook_end.set_use_custom_integrator(false)
	current_target = null
