extends Area2D


func _ready():
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")


func _on_body_entered(body):
	# All areas must follow the convention {MAT_TYPE}_{Number}
	get_parent()._on_mat_entered(body, name)


func _on_body_exited(body):
	# All areas must follow the convention {MAT_TYPE}_{Number}
	get_parent()._on_mat_exited(body, name)

