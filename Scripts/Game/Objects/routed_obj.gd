extends "res://Scripts/Game/Objects/kinematic_obj.gd"

class_name Routed

export var speed: float
export var start_index: int = 0

onready var shape: Polygon2D = $Shape
onready var direction: Node2D = $KinematicBody2D/Direction

var rotation_speed = PI/24
var point_index
var on_object_vectors = []

var angle = 0
var moving: bool = false

var on_material: Array = [Global.Surface.CONCRETE]


func _ready():
	point_index = start_index


func _physics_process(delta):
	if !dead:
		for vec in on_object_vectors:
			body.position += vec

		velocity -= Global.SURFACE_FRICTION_VALUES[on_material[-1] - 1] * velocity

		var points = shape.polygon
		var point = points[point_index]
		var displacement: Vector2 = point - body.position

		if is_equal_approx(body.rotation, angle) or moving:
			moving = true
			body.look_at(to_global(point))
			if displacement.length() > speed:
				velocity = displacement.normalized() * speed
			else:
				velocity = Vector2.ZERO
				body.position = point

				if point_index + 1 < len(points):
					point_index += 1
				else:
					point_index = 0



