extends CanvasItem

# A script for objects that can be traversed underneath, and so need features
# like reduced opacity when going under it.


func _ready():
	connect("body_entered", self, "_on_body_entered")
	connect("body_exited", self, "_on_body_exited")


func _on_body_entered(body):
	get_parent().set_modulate(Color(1, 1, 1, 0.5))


func _on_body_exited(body):
	get_parent().set_modulate(Color(1, 1, 1, 1))
