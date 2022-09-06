extends Button


func _on_HidePanel_pressed():
	get_parent().hide()
	$"../../Tabs".margin_left -= 236
	$"../../Tabs".margin_right -= 236
