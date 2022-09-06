extends Button

onready var editor = $"/root/Editor"


func _on_StopTestingButton_pressed():
	$"/root/Scene".queue_free()
	editor.tabs.set_tab_hidden(editor.TabNames.TEST, true)
