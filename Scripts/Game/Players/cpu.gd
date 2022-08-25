extends RigidBody2D


func _get_race_path():
	var paths = $"/root/Scene/Map/Paths"

	var precision = 1 # 1 pixel
	var smallest_sq_dist = INF
	var path_used = null
	for path in paths.get_children():
		var point = path.get_curve().get_closest_point(position)
		var sq_dist = position.distance_squared_to(point)
		if sq_dist < smallest_sq_dist and !is_equal_approx(sq_dist, smallest_sq_dist):
			if smallest_sq_dist - sq_dist > precision:
				smallest_sq_dist = sq_dist
				path_used = path
	return path_used


func _physics_process(delta):
	var path_used = _get_race_path()
	if path_used:
		pass
