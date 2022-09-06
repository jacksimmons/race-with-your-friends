extends Node2D


onready var paths = $"/root/Scene/Map/Paths"

var speed: float = 20
var velocity := Vector2.ZERO

var off_path: bool = false


func _physics_process(delta):
	position += velocity


func _hit_player(target_player):
	pass


func _target_player(target_player):
	var precision = 1 # 1 pixel
	var smallest_sq_dist = INF
	var path_used = target_player.cur_path

	if path_used and !off_path:
		if path_used.get_curve().get_closest_offset(position) >= \
		path_used.get_curve().get_closest_offset(target_player.position):
			# Now home in off the path
			off_path = true


		else:
			var point = path_used.get_curve().get_closest_point(position)
			look_at(point)
			position += speed * (point - position).normalized()
	elif off_path:
		if !Global._vector_is_equal_approx(target_player.position, position):
			look_at(target_player)
			position += speed * (target_player.position - position).normalized()
		else:
			_hit_player(target_player)
