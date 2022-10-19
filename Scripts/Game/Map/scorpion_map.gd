extends "res://Scripts/Game/Map/map.gd"

var player: Player

var bridge = null
var prev_z_index = null


func _ready():
	player = get_node("/root/Scene/Players/" + str(Server.STEAM_ID))


func _change_collision_layer(layer_name):
	var layers = $Layers

	for layer in layers.get_children():
		if layer.name != "col_" + layer_name:
			for obj in layer.get_children():
				if obj.get_class() == "CollisionPolygon2D":
					obj.disabled = true
				elif obj.get_class() == "Sprite":
					obj.hide()

		else:
			for obj in layer.get_children():
				if obj.get_class() == "CollisionPolygon2D":
					obj.disabled = false
				elif obj.get_class() == "Sprite":
					obj.show()


func _process(delta):
	# Handle height management
	if prev_z_index != player.z_index:
	# Ensuring we don't endlessly execute this code
		if player.z_index == 0:
			_change_collision_layer("0")

		if player.z_index == 1:
			_change_collision_layer("1")

	prev_z_index = player.z_index
