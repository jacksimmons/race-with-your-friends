extends Node2D

var ice_areas_in_contact_with_player = []
var on_ice = false

onready var on_ice_value = $"/root/Scene/Canvas/Stats/Physics/OnIce"

var player = null


func _process(delta):
	if player == null:
		player = get_node("/root/Scene/Players/" + str(Game.STEAM_ID))
	on_ice = len(ice_areas_in_contact_with_player) > 0
	if player != null:
		player.on_ice = on_ice
	on_ice_value.text = "On Ice: " + str(on_ice)


func _on_ice_entered(body, name):
	print("HIs")
	if not (ice_areas_in_contact_with_player.has(name)):
		ice_areas_in_contact_with_player.append(name)


func _on_ice_exited(body, name):
	ice_areas_in_contact_with_player.remove(name)
