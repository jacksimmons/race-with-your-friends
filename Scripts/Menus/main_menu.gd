extends Node


func _on_BackButton_pressed():
	var title_screen = load("res://Scenes/MenuTitle.tscn").instance()
	get_node("/root").add_child(title_screen)
	self.queue_free()


func _on_OnlineButton_pressed():


func _on_OfflineButton_pressed():



func _on_EditorButton_pressed():
	var editor = load("res://Scenes/Editor/Editor.tscn").instance()
	get_node("/root").add_child(editor)
	self.queue_free()
