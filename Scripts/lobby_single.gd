extends Node

onready var mapSelectPopup = $MapSelectPopup
onready var charSelectPopup = $CharSelectPopup

var host = true


func send_race_position(pos: Dictionary):
	pass


func _on_Back_pressed():
	var scene = load("res://Scenes/MenuTitle.tscn").instance()
	get_node("/root").add_child(scene)
	self.queue_free()


func _on_OpenMapSelect_pressed():
	mapSelectPopup.popup()


func _on_CloseMapSelect_pressed():
	mapSelectPopup.hide()


func _on_OpenCharSelect_pressed():
	charSelectPopup.popup()


func _on_CloseCharSelect_pressed():
	charSelectPopup.hide()


func _on_Vehicle_Selected(vehicle: String):
	Game.PLAYER_DATA[Game.STEAM_ID]["vehicle"] = vehicle
	charSelectPopup.hide()


func _on_Start_pressed():
	if !Game.PLAYER_DATA[Game.STEAM_ID].has("vehicle"):
		var random_vehicle = Global.get_random_vehicle()
		Game.PLAYER_DATA[Game.STEAM_ID]["vehicle"] = random_vehicle

	var map = preload("res://Scenes/Maps/Scorpion/ScorpionMap.tscn").instance()
	Global._setup_scene(Global.GameMode.SINGLE, map)

	self.queue_free()


func _ready():
	# Add the player data dictionary
	Game.PLAYER_DATA[Game.STEAM_ID] = {}
