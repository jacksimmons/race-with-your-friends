extends Camera2D

const DEFAULT_ZOOM = 1
const SCROLL_INC = 0.1
const SCROLL_MIN = 0.1
const SCROLL_MAX = 2

var speed = 1
var pixel_perfect = true


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
	if current:
		if Input.is_action_pressed("reset_zoom"):
			zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)

		if Input.is_action_pressed("pan_left"):
			var multiplier = speed * zoom
			if pixel_perfect:
				multiplier = Vector2(int(multiplier.x), int(multiplier.y))

			position += Vector2.LEFT * multiplier

		if Input.is_action_pressed("pan_right"):
			var multiplier = speed * zoom
			if pixel_perfect:
				multiplier = Vector2(int(multiplier.x), int(multiplier.y))

			position += Vector2.RIGHT * multiplier

		if Input.is_action_pressed("pan_up"):
			var multiplier = speed * zoom
			if pixel_perfect:
				multiplier = Vector2(int(multiplier.x), int(multiplier.y))

			position += Vector2.UP * multiplier

		if Input.is_action_pressed("pan_down"):
			var multiplier = speed * zoom
			if pixel_perfect:
				multiplier = Vector2(int(multiplier.x), int(multiplier.y))

			position += Vector2.DOWN * multiplier


func make_pixel_perfect():
	position = Vector2(int(position.x), int(position.y))
	pixel_perfect = true


func _to_cam_coordinates(pos: Vector2, multiplier: float):
	return (position + pos) * multiplier


func to_cam_coordinates_from_point(pos: Vector2):
	return _to_cam_coordinates(pos, 1/zoom.x)


func to_cam_coordinates_from_screen(pos: Vector2):
	return _to_cam_coordinates(pos, zoom.x)
