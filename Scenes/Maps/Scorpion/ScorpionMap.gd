extends Node


var bridge = null
var prev_stage_height = null


func _change_collision_level(level_name):
	var level_walls = $LevelWalls
	
	for level in level_walls.get_children():
		if level.name != level_name:
			for col in level.get_children():
				col.disabled = true
		else:
			for col in level.get_children():
				col.disabled = false


func _process(delta):
	# Handle height management
	if prev_stage_height != Global.STAGE_HEIGHT:
	# Ensuring we don't endlessly execute this code
		if Global.STAGE_HEIGHT == 0:
			print("HI")
			_change_collision_level("lv_0")
			
			if bridge != null:
				for child in get_node("/root/Scene/Foreground").get_children():
					if child == bridge:
						get_node("/root/Scene/Foreground").remove_child(child)
						break # We have found the bridge - exit
		
		if Global.STAGE_HEIGHT == -1:
			_change_collision_level("lv_-1")
			
			bridge = load("res://Scenes/Maps/Scorpion/Bridge (No Shadow).tscn").instance()
			get_node("/root/Scene/Foreground").add_child(bridge)
	
	prev_stage_height = Global.STAGE_HEIGHT
