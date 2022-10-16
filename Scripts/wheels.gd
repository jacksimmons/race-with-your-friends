extends Node2D

onready var player = get_parent()

var wheel_rotation_speed: float
var max_wheel_rotation: float

var has_wheels: bool = false
var wheel_rotation: float = 0
var rotating: bool = false
var no_wheel_rotation: bool = true
var starting_wheel_rotation: float = 0

var every_wheel_rotation: float


func _ready():
	if get_child_count() > 0:
		has_wheels = true

		# Assume all wheels have the same starting rotation, change if necessary
		starting_wheel_rotation = get_child(0).rotation_degrees

	var effective_handling = sqrt(player.HANDLING)
	wheel_rotation_speed = effective_handling * 5
	max_wheel_rotation = effective_handling * 10


func _process(delta):
	if has_wheels:
		if sign(player.current_turn) != 0 and !rotating:
			rotating = true
			# Start the wheel rotation handling
			no_wheel_rotation = false
		elif sign(player.current_turn) == 0:
			rotating = false

		if rotating:
			if abs(wheel_rotation + wheel_rotation_speed * sign(player.current_turn)) < max_wheel_rotation:
				wheel_rotation += wheel_rotation_speed * sign(player.current_turn)
			else:
				wheel_rotation = max_wheel_rotation * sign(player.current_turn)
		else:
			if wheel_rotation > 0:
				if wheel_rotation - wheel_rotation_speed > 0:
					wheel_rotation -= wheel_rotation_speed
				else:
					wheel_rotation = 0
			elif wheel_rotation < 0:
				if wheel_rotation + wheel_rotation_speed < 0:
					wheel_rotation += wheel_rotation_speed
				else:
					wheel_rotation = 0

		if !no_wheel_rotation:
			for child in get_children():
				child.rotation_degrees = starting_wheel_rotation + wheel_rotation

		if wheel_rotation == 0 and !rotating:
			# Stop the wheel rotation handling after all wheel rotation has been set to 0 and rotation has stopped
			no_wheel_rotation = true
