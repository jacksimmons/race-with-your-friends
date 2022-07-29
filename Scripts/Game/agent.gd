extends KinematicBody2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


func _process(delta):
	move_and_collide(Vector2(1, 0))
	
	# Spectating an AI:
	#var my_cam = preload("res://Scenes/Cam.tscn").instance()
	#my_cam.name = "CAM_" + str(SteamGlobals.STEAM_ID)
	#var cams = get_node("/root/Scene/Cameras")
	#my_player.add_child(my_cam)
