extends OptionButton


func _on_JoinType_visibility_changed():
	if visible:
		selected = Server.JoinType.keys().find(Server.get_lobby_data("type"))


func _on_JoinType_item_selected(index):
	# index should be in the JoinType format already
	Server.join_type = index
