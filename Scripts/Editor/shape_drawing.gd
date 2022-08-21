extends CanvasItem

onready var editor = $"/root/Editor"
onready var panel = $"/root/Editor/Canvas/UI/Panel"
onready var cam = $"/root/Editor/CamOffset/Camera2D"

var drawing = false
var viewing = false

var node: Node2D
var points: PoolVector2Array
var colours: PoolColorArray


func _ready():
	colours.append(Color.red)


func stop_drawing():
	if len(points) > 2:
		var collision = CollisionPolygon2D.new()
		collision.polygon = points

		# Updates the current node
		var staticBody :StaticBody = StaticBody.new()
		editor.current_node.add_child(collision)

		# Need to use this so that it is saved under PackedScene
		# Because this node didn't exist on startup.
		collision.owner = editor.project_root

	else:
		# Updates the current node
		editor.current_node = editor.current_node

	points = []

	for child in get_children():
		if child.name != "Vertex":
			remove_child(child)

	drawing = false


func _draw():
	if len(points) > 2:
		if drawing:
			var offset_points = []
			for point in points:
				# We have to deduct the camera's position again to show it on the screen.
				offset_points.append(point - cam.position)
			draw_polygon(offset_points, colours, PoolVector2Array())


func _input(event):
	if drawing and !viewing:
		if event is InputEventMouseButton:
			if event.is_pressed():
				if event.button_index == BUTTON_LEFT:
					var mouse_pos = get_global_mouse_position()
					if mouse_pos > panel.rect_size:
						var vertex = $Vertex.duplicate()
						vertex.position = mouse_pos
						add_child(vertex)

						# Need to place where the camera is + mouse pos
						points.append(mouse_pos + cam.position)


func _process(delta):
	update()
