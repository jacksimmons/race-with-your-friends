extends Node

# CONST VAR
var COEFFICIENT_OF_RESTITUTION = 0.1
var e = COEFFICIENT_OF_RESTITUTION

var SELECTED_VEHICLE
var SELECTED_MAP

# Stats:
# HP
# SPD: Max Speed
# ACC
# HDL: Turning
#
# ITM: Luck and Ability

const VEHICLE_BASE_STATS = {
	
	# Total stats: 20
	# Note: most vehicles have mini_car stats as a placeholder
	
	"Cock" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 1,
		"HDL" : 1,
		"WGT" : 1,
		"ITM" : 1
	}, # 6
	
	"MiniCar" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 5,
		"HDL" : 5,
		"WGT" : 1,
		"ITM" : 3
	}, # 16
	
	"CuntCar" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 5,
		"HDL" : 5,
		"WGT" : 2,
		"ITM" : 3
	}, # 17
	
	"Dankamobil" : {
		"HP" : 1,
		"SPD" : 1,
		"ACC" : 5,
		"HDL" : 2,
		"WHT" : 3,
		"ITM" : 3
	}, # 15
	
	"ShortLimo" : {
		"HP" : 2,
		"SPD" : 2,
		"ACC" : 4,
		"HDL" : 4,
		"WHT" : 3,
		"ITM" : 3
	}, # 18
	
	"LongLimo" : {
		"HP" : 2,
		"SPD" : 3,
		"ACC" : 3,
		"HDL" : 3,
		"WHT" : 4,
		"ITM" : 4
	}, # 19
	
	"JCL" : {
		"HP" : 2,
		"SPD" : 3,
		"ACC" : 2,
		"HDL" : 2,
		"WHT" : 5,
		"ITM" : 5
	} # 20
}

# Controls multi-layer levels (going under some stage elements)
var STAGE_HEIGHT = 0

enum TimeFormat {
	HOURS = 8,
	MINUTES = 4,
	SECONDS = 2,
	MILLISECONDS = 1,
	
	HHMMSSMSMS = 8 | 4 | 2 | 1,
	MMSSMSMS = 4 | 2 | 1,
	SSMSMS = 2 | 1
	
	HHMMSS = 8 | 4 | 2,
	MMSS = 4 | 2	
}

enum GameType { SINGLE, MULTI }

enum Surface {
	PLAYER = 1,
	CONTROL = 2,
	CONCRETE = 3,
	GRASS = 4,
	SAND = 5,
	ICE = 6,
	WATER = 7,
	LAVA = 8,
	CONVEYOR = 9
}


func _setup_scene(game_type: int, my_id: int):
	# Load Scene
	
	var scene = load("res://Scenes/Scene.tscn").instance()
	get_node("/root").add_child(scene)
	
	# Load the Map
	var map = load("res://Scenes/Maps/Scorpion/ScorpionMap.tscn").instance()
	var maps = get_node("/root/Scene/Map")
	maps.add_child(map)
	var checkpoints = map.get_node("Checkpoints")
	
	Game.NUM_CHECKPOINTS = checkpoints.get_child_count()
	
	# Load my Player and Camera
	var vehicle = Game.PLAYER_DATA[my_id]["vehicle"]
	var my_player = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()
	
	my_player.set_name(str(my_id))
	var players = get_node("/root/Scene/Players")
	players.add_child(my_player)
	
	var my_cam = preload("res://Scenes/Cam.tscn").instance()
	my_cam.name = "CAM_" + str(my_id)
	my_player.add_child(my_cam)
	
	var ids = Game.PLAYER_DATA.keys()
	# Load other Players and their Cameras
	
	var num_players = len(ids)
	
	if game_type == GameType.SINGLE:
		pass
	
	elif game_type == GameType.MULTI:
		for player_id in ids:
			if int(player_id) != my_id:
				var friend_vehicle = Game.PLAYER_DATA[player_id]["vehicle"]
				var friend = load("res://Scenes/Vehicles/" + friend_vehicle + ".tscn").instance()
				friend.set_name(str(player_id))
				players.add_child(friend)
				
				var cam = preload("res://Scenes/Cam.tscn").instance()
				cam.set_name("CAM_" + str(player_id))
				friend.add_child(cam)
	
	Game.PLAYER_DATA[my_id]["pre_config_complete"] = true
	
	return my_player


func _v2_to_v3(v: Vector2, z: float) -> Vector3:
	return Vector3(v.x, v.y, z)


func _find_vector_angle(v1, v2):
	# Works on v2 and v3.
	
	# Handle Vector2->Vector3 casting, errors throw for any other type.
	if typeof(v1) == TYPE_VECTOR2:
		v1 = _v2_to_v3(v1, 0)
	if typeof(v2) == TYPE_VECTOR2:
		v2 = _v2_to_v3(v2, 0)
	
	# Returns the angle between v1 and v2
	if v1 != Vector3.ZERO and v2 != Vector3.ZERO:
		# Cosine rule. Gives result in rads
		var angle = acos(v1.dot(v2) / (v1.length() * v2.length()))
		return angle
	return 0 # If a /0 error would occur, return 0


func _find_vector_direction(v1, v2):
	# Returns 1 if the second vector is over 90 degrees "away" from the
	# first vector. Makes the most sense with normalized vectors.
	var direction = 1
	if abs(_find_vector_angle(v1, v2)) >= PI/4:
		direction = -1
	return direction


func _multiply_str(string: String, times: int) -> String:
	for i in range(times):
		string += string
	return string


func _format_time(time:float, time_format: int = TimeFormat.HHMMSSMSMS) -> String:
	# A function for converting seconds into HH:MM:SS, MM:SS or SS with an optional MSMS.
	
	var seconds = int(time)
	var printable = ""
	if time_format & TimeFormat.HOURS && seconds != 0:
		var hours = str(seconds / 3600)
		if len(hours) == 1:
			hours = "0" + hours
		printable += hours + ":"
	else:
		printable += "00:"
	if time_format & TimeFormat.MINUTES && seconds != 0:
		var minutes = str(seconds / 60)
		if len(minutes) == 1:
			minutes = "0" + minutes
		printable += minutes + ":"
	else:
		printable += "00:"
	if time_format & TimeFormat.SECONDS:
		var s = str(seconds % 60)
		if len(s) == 1:
			s = "0" + s
		printable += s
	if time_format & TimeFormat.MILLISECONDS:
		var ms = time - seconds
		printable += ":" + str(ms * 1000)
	
	return printable


#func _explosion(position: Vector2, size: float):
#	var 
