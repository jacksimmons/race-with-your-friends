extends CanvasItem

onready var editor = $"/root/Editor"
onready var panel = $"/root/Editor/Canvas/UI/Panel"
onready var cam_offset = $"/root/Editor/CamOffset"
onready var cam = $"/root/Editor/CamOffset/Camera2D"
onready var vertices = $"/root/Editor/CamOffset/Vertices"

var drawing = false
var viewing = false

var node: Node2D
var points: Dictionary
var colours: PoolColorArray

var mouse_down = false
var mouse_in = false


func _ready():
	colours.append(Color(1, 0, 0, 0.25))


func stop_drawing():
	if len(points) > 2:
		var collision = CollisionPolygon2D.new()
		var global_points = []
		for vertex in points.keys():
			# Collision objects work in the global coordinate space
			global_points.append(vertex.rect_position - cam_offset.position)
		collision.polygon = global_points

		# Updates the current node
		var staticBody: StaticBody = StaticBody.new()
		editor.current_node.add_child(collision)

		# Need to use this so that it is saved under PackedScene
		# Because this node didn't exist on startup.
		collision.owner = editor.project_root

	else:
		# Updates the current node
		editor.current_node = editor.current_node

	points = {}
	drawing = false


func _draw():
	if len(points) > 0:
		if drawing:
			var offset_points = []
			for vertex in points:
				# We have to deduct the camera's position again to show it on the screen.
				var point = points[vertex]

				if point != null:
					# Divide by the zoom; vertices are closer together when zoomed out
					vertex.rect_position = cam.to_cam_coordinates_from_point(point - cam.position)
					var offset_point = (vertex.rect_position - cam.position) / cam.zoom.x + cam_offset.position
					offset_points.append(offset_point)
			draw_polygon(offset_points, colours, PoolVector2Array())


func _input(event):
	if drawing and !viewing:
		if event is InputEventMouseButton and event.button_index == BUTTON_LEFT:
			if event.is_pressed():
				mouse_down = true
			else:
				mouse_down = false


func _process(delta):
	update()

	if !drawing:
		for child in vertices.get_children():
			if child.name != "Vertex":
				vertices.remove_child(child)

	if mouse_down and mouse_in:
		# Times by the zoom; mouse placed points are further apart when zoomed out
		var mouse_pos = cam.to_cam_coordinates_from_screen(cam.get_local_mouse_position())
		var vertex = vertices.get_node("Vertex").duplicate()
		vertices.add_child(vertex)
		vertex.show()

		# This point is relative to the camera, so don't add the camera position.
		points[vertex] = mouse_pos

		mouse_down = false


func _on_Shape_mouse_entered():
	mouse_in = true


func _on_Shape_mouse_exited():
	mouse_in = false


func _on_Vertex_pressed(vertex_name: String):
	var vertex = vertices.get_node(vertex_name)
	points.erase(vertex)
	remove_child(vertex)
