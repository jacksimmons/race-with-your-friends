extends Node2D

var target_player: Vector2
var speed: float = 3


func _process(delta):
	var new_x = move_toward(position.x, target_player.x, speed)
	var new_y = move_toward(position.y, target_player.y, speed)
	rotate(get_angle_to(target_player))
	position = Vector2(new_x, new_y)
