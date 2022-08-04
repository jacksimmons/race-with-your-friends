extends Node

func _process(delta):
	if Global.STAGE_HEIGHT == -1:
		var bridge = load("res://Scenes/Maps/Foreground.tscn").instance()
		get_node("/root/Scenes/Foreground").add_child(bridge)
