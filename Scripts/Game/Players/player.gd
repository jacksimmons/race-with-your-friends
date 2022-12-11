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

onready var height_value = $"/root/Scene/Canvas/Race/Height"

onready var place_value = $"/root/Scene/Canvas/Race/Placement"

onready var lap_count_value = $"/root/Scene/Canvas/Race/LapCount"
onready var cp_count_value = $"/root/Scene/Canvas/Race/CheckpointCount"
onready var dist_value = $"/root/Scene/Canvas/Race/DistanceToNextCheckpoint"

onready var on_mat = $"/root/Scene/Canvas/Stats/Physics/OnMaterial"

onready var drawing = $"/root/Scene/Canvas/Object"
onready var hook = $Hook

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
var race_placement:int = 0

# Text
export (Color, RGB) var DEBUG_DEFAULT
export (Color, RGB) var DEBUG_WARN

# Sprite
var sprite_length

# Directions
var driving_direction: int = 0
var turning_direction: int = 0
var moving_direction: int = 0

# Power values
var engine_strength: float
var wheel_turn: float # Max rotation angle
var current_turn: float = 0 # Current rotation angle (decreases with speed)
var max_turn: float

var braking = false

# Various Forces
var driving_force: Vector2
var friction_force: Vector2
# All of the other forces acting on the vehicle
var external_force: Vector2

# Various Torques

# Stats
export var MAX_SPEED: float
export var ACCELERATION: float
export var HANDLING: float
export var WEIGHT: float
export var HP: float

var max_spd_mod = 500
var acc_mod = 100
var turn_mod = 50
var max_turn_mod = 0.01
var braking_mod = 100
var weight_mod = 10

var time = 0

var paralised = false


func _ready():
	# Get player data
	var my_data := Server.player_data[Server.STEAM_ID] as Dictionary

	mass = WEIGHT * weight_mod
	engine_strength = ACCELERATION * mass * acc_mod
	wheel_turn = HANDLING


	# When moving a kinematic body, you should not set its position directly.
	# Instead, you use the move_and_collide() or move_and_slide() methods.
	# These methods move the body along a given vector, and it will instantly
	# stop if a collision is detected with another body. After the body has
	# collided, any collision response must be coded manually.

	# Other
	sprite_length = $VehicleSprite.texture.get_height()

	# Turn
	max_turn = $Wheels.max_wheel_rotation * max_turn_mod


func _process(delta):
	if int(name) == Server.STEAM_ID:
		#! This is only because handling changes with DEBUG!
		#max_turn = get_angle_to(transform.x.rotated(wheel_turn) + Vector2(sprite_length / 2, 0))
		_handle_debug()


func _physics_process(delta):
	if int(name) == Server.STEAM_ID and !paralised:
		#var next_checkpoint_distance := position.distance_squared_to(checkpoints.get_node(str(next_checkpoint)).position)
		#race_pos = {"checkpoints": cur_checkpoint, "distance_from_next": next_checkpoint_distance}

		_handle_input()
		_handle_friction()

		set_applied_force(driving_force + friction_force + external_force)

		if linear_velocity.length() > MAX_SPEED * max_spd_mod:
			linear_velocity = linear_velocity.normalized() * MAX_SPEED * max_spd_mod

		if get_linear_velocity().length_squared() > 0:
			_handle_torque()

			moving_direction = Global._find_vector_direction(transform.x, get_linear_velocity().normalized())
		else:
			moving_direction = 0

		_handle_objects()


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
		set_applied_force(Vector2.ZERO)

	# friction
	friction_value.text = "Friction: " + str(friction)

	# hp
	hp_value.text = "HP: " + str(HP)

	# material
	on_mat.text = "On Material: " + Global.Surface.keys()[on_material[-1] - 1]

	# layer
	height_value.text = "Height: " + str(z_index)

	# race
	place_value.text = "Place: " + str(race_placement + 1) + Global.get_int_suffix(race_placement + 1)
	lap_count_value.text = "Lap: " + str(lap_count)
	cp_count_value.text = "Checkpoint: " + str(cur_checkpoint)
	dist_value.text = "Dist: " + str(get_dist_from_next_checkpoint())


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


func _calc_driving_force(driving_direction):
	return driving_direction * transform.x * engine_strength


func _calc_rotation(turning_direction):
	return turning_direction * wheel_turn


func _handle_braking():
	var velocity = get_linear_velocity()
	if velocity.length() > 2:
		driving_force = -get_linear_velocity().normalized() * engine_strength
	else:
		set_linear_velocity(Vector2.ZERO)


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

	driving_force = _calc_driving_force(driving_direction)

	turning_direction = 0
	if input_flags & InputFlags.LEFT_DOWN:
		turning_direction -= 1
	if input_flags & InputFlags.RIGHT_DOWN:
		turning_direction += 1

	current_turn = _calc_rotation(turning_direction)

	if input_flags & InputFlags.BRAKE_DOWN:
		braking = true
		_handle_braking()
	else:
		braking = false

	if input_flags & InputFlags.HOOK_DOWN:
		_handle_hook()
	if input_flags & InputFlags.BOOST_DOWN:
		max_spd *= 2.5
		net_acc *= 2.5


func get_target_position_at_next_checkpoint() -> Vector2:
	# next_checkpoint is in use as a global variable
	var checkpoints = $"/root/Scene/Checkpoints"
	var next = checkpoints.get_node(str(next_checkpoint))

	var shape: CollisionShape2D = next.get_node("CollisionShape2D")
	var segment: SegmentShape2D = shape.get_shape()
	var segment_vector: Vector2 = segment.get_a() - segment.get_b()
	var astar: AStar2D = AStar2D.new()
	astar.add_point(0, segment.get_a())
	astar.add_point(1, segment.get_b())
	astar.connect_points(0, 1)
	var next_pos = astar.get_closest_position_in_segment(position)
	return next_pos


func get_dist_from_next_checkpoint() -> int:
	var next_pos = get_target_position_at_next_checkpoint()
	return (next_pos - position).length()


func _handle_hook():
	hook.activate()


func _handle_objects():
	for vec in on_object_vectors:
		position += vec


func _handle_friction():
	friction_force = -Global.SURFACE_FRICTION_VALUES[on_material[-1] - 1] * get_linear_velocity()
	if friction_force.length() > driving_force.length():
		friction_force = -driving_force

	#var fraction_of_max_spd = velocity.length() / (200 + MAX_SPEED * 40)
	#var vel_dir = velocity.normalized()

	# Friction has a minimum value (friction) and increases with speed
	#var final_friction = (friction + fraction_of_max_spd)
	#if velocity.length() - final_friction < 0:
	#	velocity = Vector2.ZERO
	#else:
	#	velocity -= vel_dir * final_friction


func _handle_torque():
	if $Wheels.wheel_rotation != 0:
		var velocity = get_linear_velocity()
		var rot = deg2rad($Wheels.wheel_rotation)
		var turned_vector = transform.x * get_linear_velocity().length() + transform.x.rotated(rot) * turn_mod
		var turn_magnitude = Global._find_vector_angle(transform.x, turned_vector)

		if turn_magnitude > max_turn:
			turn_magnitude = max_turn

		var wheel_direction = 0
		if moving_direction == 1:
			if $Wheels.wheel_rotation < 0:
				wheel_direction = -1
			elif $Wheels.wheel_rotation > 0:
				wheel_direction = 1
		elif moving_direction == -1:
			if $Wheels.wheel_rotation < 0:
				wheel_direction = 1
			elif $Wheels.wheel_rotation > 0:
				wheel_direction = -1

		var final_turn = turn_magnitude * wheel_direction
		rotate(final_turn)

		linear_velocity = linear_velocity.rotated(final_turn)
