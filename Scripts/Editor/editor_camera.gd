extends Camera2D

const DEFAULT_ZOOM = Vector2(1, 1)
const SCROLL_INC = Vector2(0.1, 0.1)
const SCROLL_MIN = Vector2(0.1, 0.1)
const SCROLL_MAX = Vector2(2, 2)

var speed = 1
var pixel_perfect = true


func _ready():
	zoom = DEFAULT_ZOOM
	current = true


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			# Zoom In
			if event.button_index == BUTTON_WHEEL_UP and zoom - SCROLL_INC >= SCROLL_MIN:
				zoom -= SCROLL_INC

			# Zoom out
			elif event.button_index == BUTTON_WHEEL_DOWN and zoom + SCROLL_INC <= SCROLL_MAX:
				zoom += SCROLL_INC


func _process(delta):
	if Input.is_action_pressed("reset_zoom"):
		zoom = DEFAULT_ZOOM

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
