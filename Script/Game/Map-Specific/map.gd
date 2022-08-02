extends Node

func _process(delta):
	if Global.STAGE_HEIGHT == -1:
		var bridge = load("res://Scene/Maps/Foreground.tscn").instance()
		get_node("/root/Scene/Foreground").add_child(bridge)
