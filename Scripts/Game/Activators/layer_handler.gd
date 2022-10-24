extends Node2D


func _on_layer_entered(layer):
	# Name of body must be the layer of the player.
	var player = get_node("/root/Scene/Players/" + str(Server.STEAM_ID))
	if player != null:
		# Disable previous layer
		player.set_collision_mask_bit(31 - player.z_index, 0) # Level (z_index)
		player.set_collision_layer_bit(31 - player.z_index, 0) # Level (z_index)

		print(int(layer))
		player.z_index = int(layer)

		# Enable current layer.
		player.set_collision_mask_bit(31 - player.z_index, 1) #Current level
		player.set_collision_layer_bit(31 - player.z_index, 1) #Current level
