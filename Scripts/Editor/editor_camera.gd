extends Camera2D

const DEFAULT_ZOOM = 1
const SCROLL_INC = 0.1
const SCROLL_MIN = 0.1
const SCROLL_MAX = 2

var speed = 1
var pixel_perfect = false
var time = 0
var in_sprite = false


func _ready():
	zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	current = true


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			# Zoom In
			if event.button_index == BUTTON_WHEEL_UP:
				if zoom.x - SCROLL_INC > SCROLL_MIN or is_equal_approx(zoom.x - SCROLL_INC, SCROLL_MIN):
					zoom -= Vector2(SCROLL_INC, SCROLL_INC)

			# Zoom out
			elif event.button_index == BUTTON_WHEEL_DOWN:
				if zoom.x + SCROLL_INC < SCROLL_MAX or is_equal_approx(zoom.x + SCROLL_INC, SCROLL_MAX):
					zoom += Vector2(SCROLL_INC, SCROLL_INC)


func _process(delta):
	time += delta
	if current:
		var multiplier = Vector2.ZERO
		var direction = Vector2.ZERO

		if Input.is_action_pressed("reset_zoom"):
			zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)

		if Input.is_action_pressed("pan_left"):
			multiplier = get_multiplier()
			direction = Vector2.LEFT
			position += multiplier * direction

		if Input.is_action_pressed("pan_right"):
			multiplier = get_multiplier()
			direction = Vector2.RIGHT
			position += multiplier * direction

		if Input.is_action_pressed("pan_up"):
			multiplier = get_multiplier()
			direction = Vector2.UP
			position += multiplier * direction

		if Input.is_action_pressed("pan_down"):
			multiplier = get_multiplier()
			direction = Vector2.DOWN
			position += multiplier * direction


func get_multiplier():
	var multiplier = speed * zoom
	if pixel_perfect:
		multiplier = Vector2(floor(multiplier.x), floor(multiplier.y))
	return multiplier


func make_pixel_perfect():
	position = Vector2(floor(position.x), floor(position.y))
	pixel_perfect = true


func _to_cam_coordinates(pos: Vector2, multiplier: float):
	return (position + pos) * multiplier


func to_cam_coordinates_from_point(pos: Vector2):
	return _to_cam_coordinates(pos, 1/zoom.x)


func to_cam_coordinates_from_screen(pos: Vector2):
	return _to_cam_coordinates(pos, zoom.x)
