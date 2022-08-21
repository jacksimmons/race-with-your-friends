extends Node2D


func _process(delta):
	var player = get_node("/root/Scene/Players/" + str(Game.STEAM_ID))
	if player != null:

		# Disable all levels.
		player.set_collision_mask_bit(31, 0) #LEVEL0
		player.set_collision_mask_bit(30, 0) #LEVEL1
		player.set_collision_mask_bit(29, 0) #LEVEL2
		player.set_collision_mask_bit(28, 0) #LEVEL3

		# Enable current level.
		player.set_collision_mask_bit(31 - player.z_index, 1) #Current level

	pass


func _on_lv_entered(level):
	# Name of body must be the level of the player.
	var player = get_node("/root/Scene/Players/" + str(Game.STEAM_ID))
	if player != null:
		player.z_index = int(level)
