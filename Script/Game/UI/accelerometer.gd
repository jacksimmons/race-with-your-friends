extends Label

var player = null


func _process(delta):
	if player == null:
		player = get_node("/root/Scene/Players/" + str(SteamGlobals.STEAM_ID))


func _physics_process(delta):
	# 0.08 pixels per metre based on CuntCar
	if player != null:
		# We don't multiply by delta because the velocity used is already multiplied by delta.
		text = str(stepify(player.velocity.length() * 0.08, 0.01)) + " m/s"
