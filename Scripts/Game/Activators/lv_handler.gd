extends Node2D


func _process(delta):
	var player_sprite: Sprite = get_node("/root/Scene/Players/" + str(SteamGlobals.STEAM_ID) + "/Sprite")
	if player_sprite != null:
		var player: KinematicBody2D = player_sprite.get_parent()
		
		# Disable all levels.
		player.set_collision_mask_bit(31, 0) #LEVEL0
		player.set_collision_mask_bit(30, 0) #LEVEL1
		player.set_collision_mask_bit(29, 0) #LEVEL2
		player.set_collision_mask_bit(28, 0) #LEVEL3
		
		# Enable current level.
		player.set_collision_mask_bit(31 - player_sprite.z_index, 1) #Current level
		
	pass


func _on_lv_entered(body, level):
	# Name of body must be the level of the player.
	var player_sprite: Sprite = get_node("/root/Scene/Players/" + str(SteamGlobals.STEAM_ID) + "/Sprite")
	if player_sprite != null:
		print(level)
		player_sprite.z_index = int(level)
