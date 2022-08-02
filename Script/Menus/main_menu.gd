extends Node

var scene_loaded = false


func _process(delta):
	if !scene_loaded:
		if $Online/OnlineButton.pressed:
			var lobby = load("res://Scene/SteamLobby.tscn").instance()
			get_node("/root").add_child(lobby)
			scene_loaded = true
			self.queue_free()
		elif $Offline/OfflineButton.pressed:
			var char_select = load("res://Scene/CharSelect.tscn").instance()
			get_node("/root").add_child(char_select)
			scene_loaded = true
			self.queue_free()
		elif $Editor/EditorButton.pressed:
			var editor = load("res://Scene/Editor.tscn").instance()
			get_node("/root").add_child(editor)
			scene_loaded = true
			self.queue_free()
		elif $BackButton.pressed:
			var title_screen = load("res://Scene/TitleScreen.tscn").instance()
			get_node("/root").add_child(title_screen)
			scene_loaded = true
			self.queue_free()
