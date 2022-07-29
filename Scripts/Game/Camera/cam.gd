extends Camera

const DEFAULT_ZOOM = 1
const SCROLL_MIN = 0.1
const SCROLL_MAX = 2

var player
var delta_angle
var spectating = false


func _ready():
	
	set_orthogonal(1, SCROLL_MIN, SCROLL_MAX)
	player = get_parent().get_parent()
	
	if player.name != str(SteamGlobals.STEAM_ID):
		spectating = true
		set_current(false)
	
		#delta_angle = Global._find_vector_angle(player.transform.looking_at(Vector3.BACK, Vector3.UP), Vector3.BACK)


#func _input(event):
	#if !spectating:
		#if event is InputEventMouseButton:
		#	if event.is_pressed():
		#		# Zoom In
		#		if event.button_index == BUTTON_WHEEL_UP and zoom - SCROLL_INC > SCROLL_MIN:
		#			zoom -= SCROLL_INC
		#			
		#		# Zoom out
		#		elif event.button_index == BUTTON_WHEEL_DOWN and zoom + SCROLL_INC < SCROLL_MAX:
		#			zoom += SCROLL_INC
	#else:


func _process(delta):
	
	if !spectating:
		get_parent().translation += get_parent().translation - player.translation
		rotation = lerp(rotation, player.rotation, 0.2)
