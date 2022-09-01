extends Node2D

class_name Penguin

export var speed: float
export var start_index: int = 0

onready var body: KinematicBody2D = $KinematicBody2D
onready var shape: Polygon2D = $Shape
onready var direction: Node2D = $KinematicBody2D/Direction

var rotation_speed = PI/24
var point_index
var on_object_vectors = []

var angle = 0
var moving: bool = false


func _ready():
	point_index = start_index


func _process(delta):
	for vec in on_object_vectors:
		body.position += vec

	var points = shape.polygon
	var point = points[point_index]
	var displacement: Vector2 = point - body.position

	if is_equal_approx(body.rotation, angle) or moving:
		moving = true
		body.look_at(to_global(point))
		if displacement.length() > speed:
			var col = body.move_and_collide(displacement.normalized() * speed)
			if col:
				self.queue_free()
		else:
			body.position = point

			if point_index + 1 < len(points):
				point_index += 1
			else:
				point_index = 0



