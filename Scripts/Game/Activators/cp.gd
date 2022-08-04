extends Area2D


func _ready():
	connect("body_entered", self, "_on_body_entered")


func _on_body_entered(body):
	# All Checkpoint areas must follow the convention cp_{Number}
	get_parent()._on_cp_entered(body, name.substr(3))
