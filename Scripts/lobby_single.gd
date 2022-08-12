extends Node

onready var mapSelectPopup = $MapSelectPopup


func _on_Back_pressed():
	var scene = load("res://Scenes/MenuTitle.tscn").instance()
	get_node("/root").add_child(scene)
	self.queue_free()


func _on_OpenMapSelect_pressed():
	mapSelectPopup.popup()


func _on_CloseMapSelect_pressed():
	mapSelectPopup.hide()


func _on_OpenCharSelect_pressed():
	pass # Replace with function body.


func _on_Start_pressed():
	Global._setup_scene(Global.GameType.SINGLE)
