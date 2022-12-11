extends Player


func _physics_process(delta):
	var target = get_target_position_at_next_checkpoint()
	_drive_towards(target)


func _drive_towards(target: Vector2):
	var angle: float = get_angle_to(target)
	if -PI < angle and angle < PI:
		driving_force = _calc_driving_force(1)
	else:
		driving_force = _calc_driving_force(-1)

	if angle > 0:
		current_turn = _calc_rotation(1)
	else:
		current_turn = _calc_rotation(-1)
