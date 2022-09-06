extends "res://Scripts/Game/Objects/homing_obj.gd"


var flyoff_speed = speed * 2.5


func _hit_player(target_player):
	velocity = transform.x * flyoff_speed
