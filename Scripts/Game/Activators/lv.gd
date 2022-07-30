extends Area2D


func _ready():
	connect("body_entered", self, "_on_body_entered")


func _on_body_entered(body):
	get_parent()._on_lv_entered(body, name)
