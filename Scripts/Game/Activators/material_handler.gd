extends Node2D

export (preload("res://Scripts/Game/globals.gd").Surface) var surface_type

var mats_in_contact_with_player = []

#! This may be unneccessary for other players
func _on_mat_entered(body, mat_name):
	if mats_in_contact_with_player.empty():
		body.on_material.append(surface_type)
		
	if not mats_in_contact_with_player.has(mat_name):
		mats_in_contact_with_player.append(mat_name)
	# Use the most recently entered material.

func _on_mat_exited(body, mat_name):
	mats_in_contact_with_player.erase(mat_name)
	
	if mats_in_contact_with_player.size() == 0:
		body.on_material.erase(surface_type)
