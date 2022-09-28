extends OptionButton

var lobby = null
var ready = false


func _ready():
	lobby = get_node_or_null("/root/Lobby")
	ready = true


func _on_JoinType_visibility_changed():
	if visible and ready:
		selected = lobby.JoinType.keys().find(lobby.get_lobby_data("type"))
