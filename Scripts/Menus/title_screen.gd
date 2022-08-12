extends Node2D


func _on_SinglePlayerButton_pressed():
	var char_select = load("res://Scenes/LobbySingle.tscn").instance()
	get_node("/root").add_child(char_select)
	self.queue_free()


func _on_MultiPlayerButton_pressed():
	var lobby = load("res://Scenes/LobbyMulti.tscn").instance()
	get_node("/root").add_child(lobby)
	self.queue_free()


func _on_SettingsButton_pressed():
	pass # Replace with function body.


func _on_QuitButton_pressed():
	get_tree().quit()


func _on_EditorButton_pressed():
	var editor = load("res://Scenes/Editor/Editor.tscn").instance()
	get_node("/root").add_child(editor)
	self.queue_free()
