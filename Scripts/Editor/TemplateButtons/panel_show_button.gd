extends Button


func _on_ShowPanel_pressed():
	$"../Panel".show()
	$"../Tabs".margin_left += 236
	$"../Tabs".margin_right += 236
