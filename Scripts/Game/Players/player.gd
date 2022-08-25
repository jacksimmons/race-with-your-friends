extends RigidBody2D

class_name Player

const min_crash_spd = 20 #mps

### DEBUG

onready var pos_value = $"/root/Scene/Canvas/Stats/Position/PosValue"
onready var pos_button = $"/root/Scene/Canvas/Stats/Position/PosButton"
onready var spd_value = $"/root/Scene/Canvas/Stats/Speed/SpeedValue"
onready var spd_button = $"/root/Scene/Canvas/Stats/Speed/SpeedButton"
onready var spd_0er = $"/root/Scene/Canvas/Stats/Speed/SpeedZeroer"
onready var friction_value = $"/root/Scene/Canvas/Stats/Physics/Friction"
onready var hp_value = $"/root/Scene/Canvas/Stats/HP/Label"
onready var race_pos_value = $"/root/Scene/Canvas/Race/Position"
onready var lap_count_value = $"/root/Scene/Canvas/Race/LapCount"

onready var on_mat = $"/root/Scene/Canvas/Stats/Physics/OnMaterial"

onready var drawing = $"/root/Scene/Canvas/Object"
onready var hook = $HookSprite

onready var lobby = $"/root/Lobby"
onready var checkpoints = $"/root/Scene/Map/Checkpoints"
onready var powerups = get_node("/root/Scene/Powerups")

var prev_max_spd_slider = null
var prev_acc_slider = null

### END DEBUG


# Held inputs
var input_flags: int = 0
enum InputFlags {
	NONE = 0,
	FORWARD_DOWN = 1,
	REVERSE_DOWN = 2,
	LEFT_DOWN = 4,
	RIGHT_DOWN = 8,
	BRAKE_DOWN = 16,
	HOOK_DOWN = 32,
	BOOST_DOWN = 64
}

# The (optional) element put in this array before the scene is loaded
# is the default surface, for when no surface is in collision.
var on_material: Array = [Global.Surface.CONCRETE]
var on_object_vectors: Array = []

# Checkpoints
var cur_checkpoint:int = 0
var next_checkpoint:int = 0
var lap_count:int = 0
var path_count:int = 0
var race_placement:int = 0
var race_pos: Dictionary = {}
var cur_racepoint:int = 0

# Text
export (Color, RGB) var DEBUG_DEFAULT
export (Color, RGB) var DEBUG_WARN

var SURFACE_FRICTION_VALUES = \
[
	0,
	0,
	1, # Concrete
	2, # Grass
	3, # Sand
	0.5, # Ice
	5, # Water
	10, # Lava
	0, # Conveyor
]

# Sprite
var sprite_length

# Directions
var driving_direction: int = 0
var turning_direction: int = 0
var moving_direction: int = 0

# Power values
var engine_strength: float
var wheel_turn: float # Max rotation of a wheel (relative to front)
var max_turn: float # Max rotation of the whole car (relative to chassis)
var current_turn: float = 0 # Current rotation by wheels (relative to chassis)
var braking_strength: float = 150

# Various Forces
var driving_force: Vector2
var friction_force: Vector2
var braking_force: Vector2
# All of the other forces acting on the vehicle
var external_force: Vector2

# Various Torques

# Stats
export var MAX_SPEED: float
export var ACCELERATION: float
export var HANDLING: float
export var WEIGHT: float
export var HP: float

var time = 0


func _ready():
	# Get player data
	var my_data := Game.PLAYER_DATA[Game.STEAM_ID] as Dictionary

	mass = WEIGHT
	engine_strength = ACCELERATION * mass * 20
	wheel_turn = HANDLING


	# When moving a kinematic body, you should not set its position directly.
	# Instead, you use the move_and_collide() or move_and_slide() methods.
	# These methods move the body along a given vector, and it will instantly
	# stop if a collision is detected with another body. After the body has
	# collided, any collision response must be coded manually.

	# Other
	sprite_length = $VehicleSprite.texture.get_height()
	max_turn = abs(get_angle_to(transform.x.rotated(wheel_turn) + Vector2(sprite_length / 2, 0)))


func _process(delta):
	if int(name) == Game.STEAM_ID:
		#! This is only because handling changes with DEBUG!
		#max_turn = get_angle_to(transform.x.rotated(wheel_turn) + Vector2(sprite_length / 2, 0))
		_handle_debug()


func _physics_process(delta):
	if int(name) == Game.STEAM_ID:
		#var next_checkpoint_distance := position.distance_squared_to(checkpoints.get_node(str(next_checkpoint)).position)
		#race_pos = {"checkpoints": cur_checkpoint, "distance_from_next": next_checkpoint_distance}

		time += delta / Global.NETWORK_REFRESH_INTERVAL
		if time >= delta:
			print("Offset: " + str(_get_race_position()))

		_handle_input()
		_handle_objects()
		_handle_friction()

		var net_force = driving_force + braking_force + friction_force + external_force
		set_applied_force(net_force.rotated(current_turn))

		if get_linear_velocity().length_squared() > 0:
			rotate(deg2rad(current_turn))
			moving_direction = Global._find_vector_direction(transform.x, get_linear_velocity().normalized())
		else:
			moving_direction = 0


func _handle_debug():
	# Stats changable by debug UI

	# Stats UI
	# pos
	if pos_button.pressed:
		var pos_text = pos_value.text
		if pos_text != str(position):
			var y_entered = false
			var x_value = ""
			var y_value = ""
			for i in range(0, len(pos_text)):
				if pos_text[i] == ",":
					y_entered = true

				if not y_entered and pos_text[i] != "," and pos_text[i] != "(":
					x_value += pos_text[i]

				elif y_entered and pos_text[i] != "," and pos_text[i] != " " and pos_text[i] != ")":
					y_value += pos_text[i]

			position = Vector2(float(x_value), float(y_value))

	elif position != Vector2.ZERO:
		pos_value.text = "(" + str(stepify(position.x, 0.1)) + ", " + str(stepify(position.y, 0.1)) + ")"

	var velocity = get_linear_velocity()
	spd_value.text = "(" + str(stepify(velocity.x, 0.1)) + ", " + str(stepify(velocity.y, 0.1)) + ")"

	if spd_0er.pressed:
		set_linear_velocity(Vector2.ZERO)

	# friction
	friction_value.text = "Friction: " + str(friction)

	# hp
	hp_value.text = "HP: " + str(HP)

	# material
	on_mat.text = "On Material: " + Global.Surface.keys()[on_material[-1] - 1]

	# racepos
	race_pos_value.text = "Offset: " + str(_get_race_position())


func _unhandled_input(event):
	if event.is_action_pressed("forward"):
		driving_direction = 1
		input_flags |= InputFlags.FORWARD_DOWN
	elif event.is_action_released("forward"):
		driving_direction = 0
		input_flags ^= InputFlags.FORWARD_DOWN

	elif event.is_action_pressed("reverse"):
		driving_direction = -1
		input_flags |= InputFlags.REVERSE_DOWN
	elif event.is_action_released("reverse"):
		driving_direction = 0
		input_flags ^= InputFlags.REVERSE_DOWN

	elif event.is_action_pressed("left"):
		input_flags |= InputFlags.LEFT_DOWN
	elif event.is_action_released("left"):
		input_flags ^= InputFlags.LEFT_DOWN

	elif event.is_action_pressed("right"):
		input_flags |= InputFlags.RIGHT_DOWN
	elif event.is_action_released("right"):
		input_flags ^= InputFlags.RIGHT_DOWN

	elif event.is_action_pressed("brake"):
		input_flags |= InputFlags.BRAKE_DOWN
	elif event.is_action_released("brake"):
		input_flags ^= InputFlags.BRAKE_DOWN

	elif event.is_action_pressed("hook"):
		input_flags |= InputFlags.HOOK_DOWN
	elif event.is_action_released("hook"):
		input_flags ^= InputFlags.HOOK_DOWN

	elif event.is_action_pressed("boost"):
		input_flags |= InputFlags.BOOST_DOWN
	elif event.is_action_released("boost"):
		input_flags ^= InputFlags.BOOST_DOWN

	elif event.is_action_pressed("teleport"):
		global_position = get_global_mouse_position()

	elif event.is_action_pressed("eagle"):
		var eagle = preload("res://Scenes/Objects/Eagle.tscn").instance()
		eagle.position = position
		eagle.target_player = Vector2.ZERO
		powerups.add_child(eagle)

	elif event.is_action_pressed("grapple"):
		var players = get_node("/root/Scene/Players")
		var nearest_player: Node2D = null
		var nearest_player_dist: float = 0
		for player in players:
			var dist = (self.position - player.position).length()
			if dist > nearest_player_dist:
				nearest_player_dist = dist
				nearest_player = player
		if nearest_player != null:
			var hook = Line2D.new()
			hook.add_point(self.position)
			hook.add_point(nearest_player.position)
			#! Make hook tex stretch across the line until it hits a wall
			#! If it connects, pull the player to them.
		else:
			#! Do nothing, or animation??? No players.
			pass


func _get_race_position():
	var paths = $"/root/Scene/Map/Paths"

	var precision = 1 # 1 pixel
	var smallest_sq_dist = INF
	var path_used = null
	for path in paths.get_children():
		var point = path.get_curve().get_closest_point(position)
		var sq_dist = position.distance_squared_to(point)
		if sq_dist < smallest_sq_dist and !is_equal_approx(sq_dist, smallest_sq_dist):
			if smallest_sq_dist - sq_dist > precision:
				smallest_sq_dist = sq_dist
				path_used = path

	if path_used:
		print(path_used.name)
		var path_curve = path_used.get_curve()
		var points = path_curve.get_baked_points() as Array
		var path_offset = path_curve.get_closest_offset(position)

		return path_offset
	return -1

func _handle_hook():
	var targets = get_node("/root/Scene/Map/ScorpionMap/GrapplePoints")

	# Simple Djkstra's
	var shortest_path = INF
	var shortest_path_target
	for target in targets.get_children():
		if (position - target.position).length() < shortest_path:
			shortest_path_target = target

	print(shortest_path_target.position)

	drawing.lines.append({"from": position, "to": shortest_path_target.position, "col": Color.black})


func _handle_input():
	# Handles any held user input events.

	var net_acc = 0
	var net_turn = 0
	var max_spd = (200 + MAX_SPEED * 40)

	driving_direction = 0
	if input_flags & InputFlags.FORWARD_DOWN:
		driving_direction += 1
	if input_flags & InputFlags.REVERSE_DOWN:
		driving_direction -= 1

	driving_force = driving_direction * transform.x * engine_strength

	turning_direction = 0
	if input_flags & InputFlags.LEFT_DOWN:
		turning_direction -= 1
	if input_flags & InputFlags.RIGHT_DOWN:
		turning_direction += 1

	if turning_direction == 0:
		current_turn = 0

	var rot = turning_direction * wheel_turn
	if abs(current_turn + rot) < max_turn and !current_turn == max_turn:
		current_turn += rot
	else:
		current_turn = turning_direction * max_turn

	braking_force = Vector2.ZERO

	if input_flags & InputFlags.BRAKE_DOWN:
		braking_force = transform.x * -moving_direction * braking_strength

	if input_flags & InputFlags.HOOK_DOWN:
		_handle_hook()
	if input_flags & InputFlags.BOOST_DOWN:
		max_spd *= 2.5
		net_acc *= 2.5


func _handle_objects():
	for vec in on_object_vectors:
		position += vec


func _handle_friction():
	var u = SURFACE_FRICTION_VALUES[on_material[-1] - 1] # Coefficient of friction
	var r = WEIGHT * Global.g # Normal contact force

	friction_force = -driving_direction * transform.x * u * r
	if friction_force.length() > driving_force.length():
		print("=")
		friction_force = -driving_force

	#var fraction_of_max_spd = velocity.length() / (200 + MAX_SPEED * 40)
	#var vel_dir = velocity.normalized()

	# Friction has a minimum value (friction) and increases with speed
	#var final_friction = (friction + fraction_of_max_spd)
	#if velocity.length() - final_friction < 0:
	#	velocity = Vector2.ZERO
	#else:
	#	velocity -= vel_dir * final_friction
