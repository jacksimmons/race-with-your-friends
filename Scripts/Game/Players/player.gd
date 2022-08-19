extends RigidBody2D

const min_crash_spd = 20 #mps

### DEBUG

onready var pos_value = $"/root/Scene/Canvas/Stats/Position/PosValue"
onready var pos_button = $"/root/Scene/Canvas/Stats/Position/PosButton"
onready var spd_value = $"/root/Scene/Canvas/Stats/Speed/SpeedValue"
onready var spd_button = $"/root/Scene/Canvas/Stats/Speed/SpeedButton"
onready var spd_0er = $"/root/Scene/Canvas/Stats/Speed/SpeedZeroer"
onready var max_spd_slider = $"/root/Scene/Canvas/Stats/MaxSpeed/MaxSpdSlider"
onready var max_spd_value = $"/root/Scene/Canvas/Stats/MaxSpeed/MaxSpdValue"
onready var acc_slider = $"/root/Scene/Canvas/Stats/Acc/AccSlider"
onready var acc_value = $"/root/Scene/Canvas/Stats/Acc/AccValue"
onready var turn_slider = $"/root/Scene/Canvas/Stats/Turn/TurnSlider"
onready var turn_value = $"/root/Scene/Canvas/Stats/Turn/TurnValue"
onready var e_slider = $"/root/Scene/Canvas/Stats/Physics/CoRSlider"
onready var e_value = $"/root/Scene/Canvas/Stats/Physics/CoRValue"
onready var friction_value = $"/root/Scene/Canvas/Stats/Physics/Friction"
onready var hp_value = $"/root/Scene/Canvas/Stats/HP/Label"
onready var race_pos_value = $"/root/Scene/Canvas/Race/Position"

onready var on_mat = $"/root/Scene/Canvas/Stats/Physics/OnMaterial"

onready var drawing = $"/root/Scene/Canvas/Object"
onready var hook = $HookSprite

onready var lobby = $"/root/Lobby"
onready var checkpoints = $"/root/Scene/Map/ScorpionMap/Checkpoints"
onready var powerups = get_node("/root/Scene/Powerups")

var prev_max_spd_slider = null
var prev_acc_slider = null

### END DEBUG

# Base friction stat for all vehicles (decreases with offroad)
var driving_direction: int = 0
var moving_direction: int = 0


# Held inputs
var input_flags: int = 0
enum InputFlags {
	NONE = 0,
	FORWARD_DOWN = 1,
	REVERSE_DOWN = 2,
	LEFT_DOWN = 4,
	RIGHT_DOWN = 8,
	HOOK = 16,
	BOOST = 32
}

# The (optional) element put in this array before the scene is loaded
# is the default surface, for when no surface is in collision. 
var on_material: Array = [Global.Surface.CONCRETE]
var on_object_vectors: Array = []

# Checkpoints
var cur_checkpoint:int = 0
var next_checkpoint:int = 0
var race_placement:int = 0
var race_pos: Dictionary = {}

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
]

var stats: Dictionary
var engine_strength: float
var driving_force: Vector2
var friction_force: Vector2

var MAX_SPEED: float
var ACCELERATION: float
var HANDLING: float
var WEIGHT: float
var HP: int


func _ready():
	# Get player data
	var my_data := Game.PLAYER_DATA[Game.STEAM_ID] as Dictionary

	var STATS := Global.VEHICLE_BASE_STATS[my_data["vehicle"]] as Dictionary
	MAX_SPEED     = STATS["SPD"]
	ACCELERATION  = STATS["ACC"]
	HANDLING      = STATS["HDL"]
	WEIGHT        = STATS["WGT"]
	HP            = STATS["HP"]
	
	mass = WEIGHT
	engine_strength = ACCELERATION * mass

	# When moving a kinematic body, you should not set its position directly.
	# Instead, you use the move_and_collide() or move_and_slide() methods.
	# These methods move the body along a given vector, and it will instantly
	# stop if a collision is detected with another body. After the body has
	# collided, any collision response must be coded manually.
	
	# Debug
	max_spd_slider.value = MAX_SPEED
	acc_slider.value = ACCELERATION
	turn_slider.value = HANDLING
	e_slider.value = Global.e


func _process(delta):
	_handle_debug()


func _physics_process(delta):
	if int(name) == Game.STEAM_ID:
		var next_checkpoint_distance := position.distance_squared_to(checkpoints.get_node(str(next_checkpoint)).position)
		race_pos = {"checkpoints": cur_checkpoint, "distance_from_next": next_checkpoint_distance}
		
		_handle_input()
		_handle_objects()
		_handle_friction()
		
		set_applied_force(driving_force + friction_force)


func _handle_debug():
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
		
	spd_value.text = str(get_linear_velocity().length())
	
	if spd_0er.pressed:
		set_linear_velocity(Vector2.ZERO)
	
	# max speed
	max_spd_value.text = str(max_spd_slider.value)
	if prev_max_spd_slider != null and prev_max_spd_slider != max_spd_slider.value:
		MAX_SPEED = max_spd_slider.value
	prev_max_spd_slider = max_spd_slider.value
	
	# acc
	acc_value.text = str(acc_slider.value)
	if prev_acc_slider != null and prev_acc_slider != acc_slider.value:
		ACCELERATION = acc_slider.value
	prev_acc_slider = acc_slider.value
	
	if (acc_slider.value >= max_spd_slider.value
		or acc_slider.value == 0):
		max_spd_value.set("custom_colors/font_color", DEBUG_WARN)
		acc_value.set("custom_colors/font_color", DEBUG_WARN)
	else:
		max_spd_value.set("custom_colors/font_color", DEBUG_DEFAULT)
		acc_value.set("custom_colors/font_color", DEBUG_DEFAULT)
	
	# turn
	turn_value.text = str(turn_slider.value)
	if turn_slider.value != 0:
		HANDLING = turn_slider.value
		turn_value.set("custom_colors/font_color", DEBUG_DEFAULT)
	else:
		turn_value.set("custom_colors/font_color", DEBUG_WARN)
	
	# e
	e_value.text = str(e_slider.value)
	Global.e = e_slider.value
	
	# friction
	friction_value.text = "Friction: " + str(friction)
	
	# hp
	hp_value.text = "HP: " + str(HP)
	
	# material
	on_mat.text = "On Material: " + Global.Surface.keys()[on_material[-1] - 1]
	
	race_pos_value.text = "Position " + str(race_placement)


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
	
	elif event.is_action_pressed("hook"):
		input_flags |= InputFlags.HOOK
	elif event.is_action_released("hook"):
		input_flags ^= InputFlags.HOOK
	
	elif event.is_action_pressed("boost"):
		input_flags |= InputFlags.BOOST
	elif event.is_action_released("boost"):
		input_flags ^= InputFlags.BOOST
	
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

	if input_flags & InputFlags.LEFT_DOWN:
		net_turn -= moving_direction
	if input_flags & InputFlags.RIGHT_DOWN:
		net_turn += moving_direction
	if input_flags & InputFlags.HOOK:
		_handle_hook()
	if input_flags & InputFlags.BOOST:
		max_spd *= 2.5
		net_acc *= 2.5
	
	#_turn(net_turn, HANDLING)


func _handle_objects():
	for vec in on_object_vectors:
		position += vec


func _handle_friction():
	var u = SURFACE_FRICTION_VALUES[on_material[-1]] # Coefficient of friction
	var r = WEIGHT * Global.g # Normal contact force
	
	friction_force = -driving_direction * transform.x * u * r
	if friction_force > driving_force:
		friction_force = driving_force
	
	#var fraction_of_max_spd = velocity.length() / (200 + MAX_SPEED * 40)
	#var vel_dir = velocity.normalized()
	
	# Friction has a minimum value (friction) and increases with speed 
	#var final_friction = (friction + fraction_of_max_spd)
	#if velocity.length() - final_friction < 0:
	#	velocity = Vector2.ZERO
	#else:
	#	velocity -= vel_dir * final_friction
