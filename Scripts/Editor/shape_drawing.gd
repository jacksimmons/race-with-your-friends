extends CanvasItem

onready var editor = $"/root/Editor"

var drawing = false
var node: Node2D
var points: PoolVector2Array
var colours: PoolColorArray


func _ready():
	colours.append(Color.red)


func _draw():
	if len(points) > 2:
		if drawing:
			draw_polygon(points, colours, PoolVector2Array())
		else:
			var collision = CollisionPolygon2D.new()
			collision.polygon = points
			
			points = []
			
			for child in get_children():
				if child.name != "Vertex":
					remove_child(child)
			
			editor.current_node.add_child(collision)
			editor.refresh_nodes()


func _input(event):
	if drawing:
		if event is InputEventMouseButton:
			if event.is_pressed():
				if event.button_index == BUTTON_LEFT:
					var mouse_pos = get_global_mouse_position()
					var vertex = $Vertex.duplicate()
					vertex.position = mouse_pos
					add_child(vertex)
					points.append(mouse_pos)


func _process(delta):
	update()
