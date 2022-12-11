extends RigidBody2D


# Transform (tr) at collision instant (ci) from the collider to the player
# https://godotengine.org/qa/27382/making-a-rigidbody-stick-on-a-moving-kinematicbody
var tr_ci_collider_to_player = Transform2D()
var is_sticking = false
var body_stuck_on = null


func _integrate_forces(state):
	if !is_sticking and state.get_contact_count() == 1:
		is_sticking = true

		# Ignore custom integrator once sticking
		#set_use_custom_integrator(false)

		# Get the RB on which the player will stick (the only one as contacts=1)
		body_stuck_on = state.get_contact_collider_object(0)

		print("Stuck on: " + body_stuck_on.name)

		var tr_ci_world_to_player = get_global_transform()
		var tr_ci_world_to_collider = body_stuck_on.get_global_transform()
		# collider->player        = (collider->world) -> (world->player)
		# (Multiply matrices)     = (collider->world) * (world->player)
		# (Basic inverse law)     = (world->collider)^(-1) * (world->player)
		tr_ci_collider_to_player = tr_ci_world_to_collider.inverse() * tr_ci_world_to_player

	if is_sticking:
		# Take the last transform of the moving collider
		# Keep the same relative position of the player to the collider...
		# ...at the instant of the collision
		global_transform = body_stuck_on.get_global_transform() * tr_ci_collider_to_player
