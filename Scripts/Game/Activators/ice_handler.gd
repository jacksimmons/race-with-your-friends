extends Area2D


func _ready():
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")


func _on_body_entered(body):
	# All Ice areas must follow the convention ice_{Number}
	get_parent()._on_ice_entered(body, name.substr(4))


func _on_body_exited(body):
	# All Ice areas must follow the convention ice_{Number}
	get_parent()._on_ice_exited(body, name.substr(4))
