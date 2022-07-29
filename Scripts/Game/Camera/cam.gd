extends Camera2D

const DEFAULT_ZOOM = 1
const SCROLL_INC = Vector2(0.1, 0.1)
const SCROLL_MIN = Vector2(0.1, 0.1)
const SCROLL_MAX = Vector2(2, 2)

var player
var delta_angle
var spectating = false


func _ready():
	zoom = Vector2(DEFAULT_ZOOM, DEFAULT_ZOOM)
	player = get_parent().get_parent()
	
	if player.name != str(SteamGlobals.STEAM_ID):
		spectating = true
	
	delta_angle = Global._find_vector_angle(player.position.x, Vector2.UP)
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
		current = true
	else:
		current = false


func _process(delta):
	if !spectating:
		position = player.position
		rotation = lerp_angle(rotation, player.rotation + delta_angle, 0.2)
		current = true
	else:
		current = false
