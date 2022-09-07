extends Button

onready var editor = $"/root/Editor"


func _on_StopTestingButton_pressed():
	$"/root/Scene".queue_free()
	editor.stop_testing()
