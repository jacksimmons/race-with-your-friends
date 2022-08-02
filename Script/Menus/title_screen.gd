extends Node2D

var main_menu_loaded = false

func _process(delta):
	if $PlayButton.pressed and !main_menu_loaded:
		# Load the main menu
		var main_menu = load("res://Scene/MainMenu.tscn").instance()
		get_node("/root").add_child(main_menu)
		main_menu_loaded = true
		self.queue_free()
		
	if $QuitButton.pressed:
		get_tree().quit()
