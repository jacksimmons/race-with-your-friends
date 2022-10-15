extends Node

# Set at main menu
var DEBUG_COLLISION_SHAPES

var g = 9.81
var COEFFICIENT_OF_RESTITUTION = 0.1
var e = COEFFICIENT_OF_RESTITUTION

# Controls multi-layer levels (going under some stage elements)
var STAGE_HEIGHT = 0

var SURFACE_FRICTION_VALUES = \
[
	0,
	0,
	0.1, # Concrete
	2, # Grass
	3, # Sand
	0.5, # Ice
	5, # Water
	10, # Lava
	0, # Conveyor
]

const VEHICLES: Array =\
[
	"Cock",
	"MiniCar",
	"CuntCar",
	"DankaMobil",
	"ShortLimo",
	"LongLimo",
	"JCL"
]

const MAPS: Array =\
[
	"ScorpionMap",
	"TemporaryCockMap"
]

const MAP_PLAYER_LIMITS: Dictionary =\
{
	"ScorpionMap": 12,
	"TemporaryCockMap": 4
}

const PLAYER_COLOUR_LIST: Array =\
[
	Color.red,
	Color.aqua,
	Color.green,
	Color.yellow,
	# 4
	Color.hotpink,
	Color.blue,
	Color.turquoise,
	Color.orange,
	# 8
	Color.crimson,
	Color.purple,
	Color.darkgreen,
	Color.chocolate,
	# 12
	Color.orangered,
	Color.indigo,
	Color.darkseagreen,
	Color.salmon,
	# 16
	Color.fuchsia,
	Color.cornflower,
	Color.olive,
	Color.gold,
	# 20
	Color.burlywood,
	Color.midnightblue,
	Color.white,
	Color.black,
	# 24
]

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

enum GameMode { SINGLE, MULTI, EDITOR }
var GAME_MODE

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

enum SceneType { VEHICLE, MAP }


func get_int_suffix(var integer: int):
	var final_digit = str(integer)[-1]
	match final_digit:
		1:
			if str(integer).substr(-2, 2) != "11":
				return "st"
			return "th"
		2:
			if str(integer).substr(-2, 2) != "12":
				return "nd"
			return "th"
		3:
			if str(integer).substr(-2, 2) != "13":
				return "rd"
			return "th"
		_:
			return "th"


func slot_in(var item, var array: Array, var index: int) -> Array:
	# Negative increment for loop to move elements one along
	array.append(null)
	for i in range(len(array) - 1, index, -1):
		array[i+1] = array[i]
	array[index+1] = item
	return array


func get_random_arrayitem(var array: Array):
	randomize()
	var item = array[randi() % array.size()]
	return item


func get_random_scene(var scene_type: int) -> String:
	var valid_scenes
	match scene_type:
		SceneType.VEHICLE:
			valid_scenes = VEHICLES
		SceneType.MAP:
			valid_scenes = MAPS
	return get_random_arrayitem(valid_scenes)


func _setup_scene(game_mode: int, map: Node2D, race_pos: int):
	# Sets up a game scene using Global and Game data.
	var my_id = Game.STEAM_ID

	# Load Scene
	var scene = preload("res://Scenes/Scene.tscn").instance()
	get_node("/root").add_child(scene)

	# Load the Map
	scene.get_node("Map").replace_by(map)
	var checkpoints = map.get_node("Checkpoints")

	Game.NUM_CHECKPOINTS = checkpoints.get_child_count()

	# Load my Player and Camera
	var vehicle = Game.PLAYER_DATA[my_id]["vehicle"]
	var my_player = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()

	my_player.set_name(str(my_id))
	var players = get_node("/root/Scene/Players")
	var start_point = map.get_node("StartPoints").get_node(str(race_pos))
	var point_l = start_point.get_node("Front").position
	var point_r = start_point.get_node("Back").position
	my_player.position = (point_l + point_r) / 2
	my_player.position.x -= my_player.get_node("VehicleSprite").get_texture().get_height() / 2
	players.add_child(my_player)

	var my_cam = preload("res://Scenes/Cam.tscn").instance()
	my_cam.name = "CAM_" + str(my_id)
	my_player.add_child(my_cam)

	if game_mode == GameMode.SINGLE:
		pass

	elif game_mode == GameMode.MULTI:
		var ids = Game.PLAYER_DATA.keys()
		var num_players = len(ids)

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
	GAME_MODE = game_mode


	return my_player


func _find_vector_angle(v1, v2) -> float:
	# Returns the angle between v1 and v2
	if v1 != Vector2.ZERO and v2 != Vector2.ZERO:
		# Cosine rule. Gives result in rads
		var input = v1.dot(v2) / (v1.length() * v2.length())

		# Bind the input to avoid NAN output
		if input > 1:
			input = 1
		elif input < -1:
			input = -1

		var angle = acos(input)
		return angle
	return 0.0 # If a /0 error would occur, return 0


func _find_vector_direction(v1, v2):
	# Returns 1 if the second vector is over 90 degrees "away" from the
	# first vector. Makes the most sense with normalized vectors.
	var direction = 1
	if abs(_find_vector_angle(v1, v2)) >= PI/2:
		direction = -1
	return direction


func _vector_is_equal_approx_to_step(v1, v2, step):
	var v1_rounded = Vector2(stepify(v1.x, step), stepify(v1.y, step))
	var v2_rounded = Vector2(stepify(v2.x, step), stepify(v2.y, step))

	return _vector_is_equal_approx(v1_rounded, v2_rounded)


func _vector_is_equal_approx(v1, v2):
	if is_equal_approx(v1.x, v2.x) and is_equal_approx(v1.y, v2.y):
		return true
	return false


func vector_stepify(vector, step):
	return Vector2(stepify(vector.x, step), stepify(vector.y, step))


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


# RUNNING CODE
func _unhandled_key_input(event):
	if event.is_action_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
