extends Node2D

export (preload("res://Scripts/Game/globals.gd").Surface) var surface_type

var mats_in_contact_with = {}

#! This may be unneccessary for other players
func _on_mat_entered(body, mat_name):
	if not body in mats_in_contact_with:
		mats_in_contact_with[body] = []

	mats_in_contact_with[body].append(mat_name)
	body.on_material.append(surface_type)


func _on_mat_exited(body, mat_name):
	mats_in_contact_with[body].erase(mat_name)

	if mats_in_contact_with[body].size() == 0:
		body.on_material.erase(surface_type)
