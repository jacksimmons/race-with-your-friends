extends Area2D


func _ready():
	connect("body_shape_entered", self, "_on_body_shape_entered")


func _on_body_shape_entered(body_rid, body, body_shape_index, local_shape_index, level:int):
	print(level)
	get_parent()._on_lv_entered(level)
