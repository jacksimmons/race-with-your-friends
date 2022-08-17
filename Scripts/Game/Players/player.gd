extends KinematicBody2D

const min_crash_spd = 20 #mps

### DEBUG

onready var pos_value = get_node("../../Canvas/Stats/Position/PosValue")
onready var pos_button = get_node("../../Canvas/Stats/Position/PosButton")
onready var spd_value = get_node("../../Canvas/Stats/Speed/SpeedValue")
onready var spd_button = get_node("../../Canvas/Stats/Speed/SpeedButton")
onready var spd_0er = get_node("../../Canvas/Stats/Speed/SpeedZeroer")
onready var max_spd_slider = get_node("../../Canvas/Stats/MaxSpeed/MaxSpdSlider")
onready var max_spd_value = get_node("../../Canvas/Stats/MaxSpeed/MaxSpdValue")
onready var acc_slider = get_node("../../Canvas/Stats/Acc/AccSlider")
onready var acc_value = get_node("../../Canvas/Stats/Acc/AccValue")
onready var turn_slider = get_node("../../Canvas/Stats/Turn/TurnSlider")
onready var turn_value = get_node("../../Canvas/Stats/Turn/TurnValue")
onready var e_slider = get_node("../../Canvas/Stats/Physics/CoRSlider")
onready var e_value = get_node("../../Canvas/Stats/Physics/CoRValue")
onready var friction_value = get_node("../../Canvas/Stats/Physics/Friction")
onready var hp_value = get_node("../../Canvas/Stats/HP/Label")
onready var race_pos_value = get_node("../../Canvas/Race/Position")

onready var on_mat = $"/root/Scene/Canvas/Stats/Physics/OnMaterial"


onready var lobby = get_node("/root/Lobby")
onready var checkpoints = get_node("/root/Scene/Map/ScorpionMap/Checkpoints")
onready var powerups = get_node("/root/Scene/Powerups")

var bot = false
var offline = true

var MAX_SPEED
var ACCELERATION
var HANDLING
var HP

var prev_max_spd_slider = null
var prev_acc_slider = null

### END DEBUG

# Base friction stat for all vehicles (decreases with offroad)
var driving_direction: int = 0
var moving_direction: int = 0

# Held inputs
var input_flags: int = 0
enum InputFlags {
	FORWARD_DOWN = 1,
	REVERSE_DOWN = 2,
	LEFT_DOWN = 4,
	RIGHT_DOWN = 8,
	
	NONE = 0
}

# Friction
var friction

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

export (Array, float) var SURFACE_FRICTION_VALUES

var my_data: Dictionary
var stats: Dictionary
var velocity: Vector2

var prev_max_spd

var scene_loaded: bool = false

func _ready():	
	# Get player data
	my_data = Game.PLAYER_DATA[int(name)]

	var STATS = Global.VEHICLE_BASE_STATS[my_data["vehicle"]]
	MAX_SPEED     = STATS["SPD"]
	ACCELERATION  = STATS["ACC"]
	HANDLING      = STATS["HDL"]
	HP            = STATS["HP"]

	# When moving a kinematic body, you should not set its position directly.
	# Instead, you use the move_and_collide() or move_and_slide() methods.
	# These methods move the body along a given vector, and it will instantly
	# stop if a collision is detected with another body. After the body has
	# collided, any collision response must be coded manually.
	
	scene_loaded = true


func _process(delta):
	_handle_debug()


func _physics_process(delta):
	if int(name) == Game.STEAM_ID:
		var next_checkpoint_distance = position.distance_squared_to(checkpoints.get_node(str(next_checkpoint)).position)
		race_pos = {"checkpoints": cur_checkpoint, "distance_from_next": next_checkpoint_distance}
	
		var collision_info = move_and_collide(velocity * delta)
		if collision_info:
			print("H")
			var collider = collision_info.collider
			
			# Damage
			var residual_speed = collision_info.remainder.length_squared()
			HP -= residual_speed
			
			# Collision
			#var speed_mps = velocity.length() * 0.08
			#if speed_mps >= min_crash_spd:
				# If velocity >= 20mps:
			#	var damage = int(ceil(speed_mps - min_crash_spd) / 10) + 1
				
			velocity *= -Global.e
		
		_handle_input()
		_handle_objects()
		_handle_friction()


var debug_setup = false
func _handle_debug():
	if scene_loaded and !bot:
		# Does debug need setting up?
		if !debug_setup:
			max_spd_slider.value = MAX_SPEED
			acc_slider.value = ACCELERATION
			turn_slider.value = HANDLING
			e_slider.value = Global.e
			
			debug_setup = true
		
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
			
		spd_value.text = str(velocity.length())
		
		if spd_0er.pressed:
			velocity = Vector2.ZERO
		
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


func _accelerate(acc, max_spd):
	moving_direction = Global._find_vector_direction(velocity.normalized(), transform.x)
	
	if acc >= 0 and moving_direction * velocity.length() + acc < max_spd:
		velocity += acc * transform.x
			
	elif acc <= 0 and moving_direction * velocity.length() - acc > -max_spd:
		velocity += acc * transform.x
			
	else:
		velocity = velocity.normalized() * max_spd


func _turn(dir, hdl):
	# d1
	var previous_forward_vector = transform.x
	var angle = hdl / 200
	var rotation_vector = velocity.rotated(angle)
	var rotation_angle = dir * (Global._find_vector_angle(velocity, rotation_vector))
	rotation += rotation_angle
	
	# d2
	var new_forward_vector = transform.x
	
	# Align the car's velocity with the direction it is now facing.
	# d1->d2 = d2 - d1
	var forward_vector_traversal = new_forward_vector - previous_forward_vector
	
	# Add the vector traversal for direction to velocity, multiplied by the magnitude of velocity
	# We also need to consider forward and reverse motion: for forward, traversal is added,
	# and for reverse, traversal is subtracted.
	# (As transform.x is a unit vector)
	var direction = Global._find_vector_direction(velocity, previous_forward_vector)
	velocity += direction * forward_vector_traversal * velocity.length()


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


func _handle_input():
	# Handles any held user input events.
	
	var net_acc = 0
	var net_turn = 0
	var max_spd = (200 + MAX_SPEED * 40)
	
	if input_flags & InputFlags.FORWARD_DOWN:
		net_acc += ACCELERATION
	if input_flags & InputFlags.REVERSE_DOWN:
		net_acc -= ACCELERATION
	if input_flags & InputFlags.LEFT_DOWN:
		net_turn -= moving_direction
	if input_flags & InputFlags.RIGHT_DOWN:
		net_turn += moving_direction
	
	_accelerate(net_acc, max_spd)
	_turn(net_turn, HANDLING)
	
	# Debug
	if Input.is_action_just_pressed("teleport"):
		global_position = get_global_mouse_position()
	
	if Input.is_action_just_pressed("boost"):
		ACCELERATION *= 100
		prev_max_spd = MAX_SPEED
		MAX_SPEED = 10
	
	if Input.is_action_just_pressed("boost"):
		ACCELERATION /= 100
		MAX_SPEED = prev_max_spd
	
	if Input.is_action_just_pressed("eagle"):
		var eagle = preload("res://Scenes/Objects/Eagle.tscn").instance()
		eagle.position = position
		eagle.target_player = Vector2.ZERO
		powerups.add_child(eagle)
	
	if Input.is_action_just_pressed("grapple"):
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


func _handle_objects():
	for vec in on_object_vectors:
		position += vec


func _handle_friction():
	friction = SURFACE_FRICTION_VALUES[on_material[-1]]
	var fraction_of_max_spd = velocity.length() / (200 + MAX_SPEED * 40)
	var vel_dir = velocity.normalized()
	
	# Friction has a minimum value (friction) and increases with speed 
	var final_friction = (friction + fraction_of_max_spd)
	if velocity.length() - final_friction < 0:
		velocity = Vector2.ZERO
	else:
		velocity -= vel_dir * final_friction
