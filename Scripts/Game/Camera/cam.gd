extends Camera2D

const DEFAULT_ZOOM = 1
const SCROLL_INC = Vector2(0.1, 0.1)
const SCROLL_MIN = Vector2(0.1, 0.1)
const SCROLL_MAX = Vector2(2, 2)

onready var player = get_parent().get_parent()

var delta_angle
var spectating = false
var check_player_name = true


func _ready():
	zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)

	rotation = Global._find_vector_angle(player.transform.x, Vector2.UP)
	rotating = true


func _input(event):
	if !spectating:
		if event is InputEventMouseButton:
			if event.is_pressed():
				# Zoom In
				if event.button_index == BUTTON_WHEEL_UP and zoom - SCROLL_INC > SCROLL_MIN:
					zoom -= SCROLL_INC

				# Zoom out
				elif event.button_index == BUTTON_WHEEL_DOWN and zoom + SCROLL_INC < SCROLL_MAX:
					zoom += SCROLL_INC


func _process(delta):
	if player and player.name != "Player" and check_player_name:
		check_player_name = false
		if player.name != str(Server.STEAM_ID):
			spectating = true
		else:
			current = true
