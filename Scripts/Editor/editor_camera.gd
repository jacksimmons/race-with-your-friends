extends Camera2D

const DEFAULT_ZOOM = Vector2(1, 1)
const SCROLL_INC = Vector2(0.1, 0.1)
const SCROLL_MIN = Vector2(0.1, 0.1)
const SCROLL_MAX = Vector2(2, 2)

var speed = 1


func _ready():
	zoom = DEFAULT_ZOOM


func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			# Zoom In
			if event.button_index == BUTTON_WHEEL_UP and zoom - SCROLL_INC > SCROLL_MIN:
				zoom -= SCROLL_INC
				
			# Zoom out
			elif event.button_index == BUTTON_WHEEL_DOWN and zoom + SCROLL_INC < SCROLL_MAX:
				zoom += SCROLL_INC


func _process(delta):
	if Input.is_action_pressed("reset_zoom"):
		zoom = DEFAULT_ZOOM
	
	if Input.is_action_pressed("pan_left"):
		position += Vector2.LEFT * speed
	
	if Input.is_action_pressed("pan_right"):
		position += Vector2.RIGHT * speed

	if Input.is_action_pressed("pan_up"):
		position += Vector2.UP * speed
	
	if Input.is_action_pressed("pan_down"):
		position += Vector2.DOWN * speed
