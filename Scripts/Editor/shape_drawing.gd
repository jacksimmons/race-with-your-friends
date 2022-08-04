extends CanvasItem

var drawing = false
var node: Node2D
var points: PoolVector2Array
var colours: PoolColorArray


func _ready():
	colours.append(Color.red)


func _draw():
	if len(points) > 2:
		draw_polygon(points, colours, PoolVector2Array())


func _input(event):
	if drawing:
		if event is InputEventMouseButton:
			if event.is_pressed():
				if event.button_index == BUTTON_LEFT:
					var vertex = $Vertex.duplicate()
					var mouse_pos = get_global_mouse_position()
					vertex.position = mouse_pos
					add_child(vertex)
					points.append(mouse_pos)


func _process(delta):
	update()
