extends "res://Scripts/Game/Map/map.gd"


var bridge = null
var prev_stage_height = null


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
	if prev_stage_height != Global.STAGE_HEIGHT:
	# Ensuring we don't endlessly execute this code
		if Global.STAGE_HEIGHT == 0:
			_change_collision_layer("0")

		if Global.STAGE_HEIGHT == 1:
			_change_collision_layer("1")

	prev_stage_height = Global.STAGE_HEIGHT
