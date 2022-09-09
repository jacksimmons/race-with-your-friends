extends Node

enum TabNames {
	CAMERA = 0,
	MAP = 1,
	TEST = 2,
	OBJ = 3
}


var ground_names = ["Concrete", "Tyre", "Grass", "Ice", "Sand", "Lava"]
var ground_names_already_present = []
var ground_names_to_colour = \
{
	"Concrete": Color.darkgray,
	"Tyre": Color.black,
	"Grass": Color.greenyellow,
	"Ice": Color.aquamarine,
	"Sand": Color.yellow,
	"Lava": Color.orangered
}

var wall_names = ["Solid", "Bouncy"]
var wall_names_already_present = []

var highest_layer_no: int = -1
var max_layers: int = 4

var highest_checkpoint_no: int = -1

var current_file: String = ""
var current_node: Node
var current_pan: float

var obj_sprite_loaded: bool = false

onready var project_root = $Object

onready var buttons = $Canvas/UI/Panel/Buttons

onready var cam_pan_label = $Canvas/UI/Tabs/Camera/CamPan/CameraPanLabel
onready var cam_pan_slider = $Canvas/UI/Tabs/Camera/CamPan/CameraPan
onready var cam_pos = $Canvas/UI/Tabs/Camera/CamPos/CameraPos
onready var cam_zoom = $Canvas/UI/Tabs/Camera/CamZoom/CameraZoom
onready var cam_pp = $Canvas/UI/Tabs/Camera/PixPerf/PixelPerfectButton
onready var cam_rot_label = $Canvas/UI/Tabs/Camera/CamRot/CameraRotationLabel
onready var cam_rot_slider = $Canvas/UI/Tabs/Camera/CamRot/CameraRotation

onready var display = $CamOffset/Display
onready var cam = $CamOffset/Camera2D
onready var shape = $Canvas/Shape
onready var path = $Canvas/UI/Path
onready var tabs = $Canvas/UI/Tabs
onready var axes = $CamOffset/Axes
var axes_visible: bool

onready var save: MenuButton = $Canvas/UI/Panel/File/Save

onready var obj_sprite = $Map/Sprites/MapSprite

var progress = false

func _ready():
	current_node = $Object
	cam_pp.set_pressed(true)

	_on_CameraPan_value_changed(cam_pan_slider.value)
	_on_CameraRotation_value_changed(cam_rot_slider.value)

	tabs.set_tab_hidden(TabNames.MAP, true) # Map
	tabs.set_tab_hidden(TabNames.TEST, true) # Testing
	tabs.set_tab_hidden(TabNames.OBJ, true) # Testing


func clear_current_file():
	# For when a New file is selected, or an internal game scene is opened.
	# The user will have to save the scene as a new one, rather than overwriting.
	current_file = ""
	save.get_popup().remove_item(2)


func replace_project_root(new_root:Node):
	remove_child(project_root)
	add_child(new_root)
	move_child(new_root, 0)
	project_root = new_root
	current_node = project_root

	if current_node.name == "Map":
		for ggchild in current_node.get_node("Ground").get_children():
			ground_names_already_present.append(ggchild.name)
		for ggchild in current_node.get_node("Walls").get_children():
			wall_names_already_present.append(ggchild.name)
		tabs.set_tab_hidden(TabNames.MAP, false)
		tabs.set_tab_hidden(TabNames.OBJ, false)


func add_button_font_colour_override(button:Button, colour:Color):
	button.add_color_override("font_color", colour)
	button.add_color_override("font_color_disabled", colour)
	button.add_color_override("font_color_focus", colour)
	button.add_color_override("font_color_hover", colour)
	button.add_color_override("font_color_pressed", colour)


func delete_all_children(node, exceptions=[]):
	if node.get_child_count() > 0:
		for child in node.get_children():
			if not child.name in exceptions:
				node.remove_child(child)


func start_testing():
	tabs.set_tab_hidden(TabNames.TEST, false)
	if axes.visible:
		axes_visible = true
	axes.hide()


func stop_testing():
	tabs.set_tab_hidden(TabNames.TEST, true)
	if axes_visible:
		axes.show()
	cam.current = true


func refresh_nodes():
	progress = true
	var path_text = str(get_path_to(current_node)) + " [" + str(current_node.get_class()) + "]"
	if current_file != "":
		path_text += " (" + current_file + ")"
	path.text = path_text

	#delete_all_children(tabs, ["Camera", "File"])
	delete_all_children(display)

	var visible_node = current_node.duplicate()
	visible_node.visible = true
	visible_node.position = cam.get_parent().position # Place the node at the camera offset
	display.add_child(visible_node)

	# Clear shape points
	shape.points = {}

	# Hide any tabs which hide by refreshing
	tabs.set_tab_hidden(TabNames.OBJ, true)


	if buttons.get_child_count() > 0:
		for button in buttons.get_children():
			buttons.remove_child(button)

	if current_node.get_parent() != self:
		# If the node has a viewable parent...
		var current_parent = current_node.get_parent()
		var button = preload("res://Scenes/Editor/ChangeNodeButton.tscn").instance()
		var button_text = "Back [" + current_parent.name + "]"
		button.in_scene = true
		button.node = current_parent
		button.text = button_text
		buttons.add_child(button)

	var children = current_node.get_children()
	for child in children:
		if child is Node2D:
			# Make all the buttons necessary to display all children.
			var button = preload("res://Scenes/Editor/ChangeNodeButton.tscn").instance()
			var button_text = child.get_name()
			var child_count = child.get_child_count()
			if child_count > 0:
				button_text += " [" + str(child_count) + "]"
			button.in_scene = true
			button.node = child
			button.text = button_text
			buttons.add_child(button)

	if current_node is Sprite:
		obj_sprite_loaded = false

		# Sprite management button.
		if !current_node.texture:
			var button = preload("res://Scenes/Editor/ImportSpriteButton.tscn").instance()
			button.text = "Import Sprite"
			button.sprite_node = current_node
			add_button_font_colour_override(button, Color.hotpink)
			buttons.add_child(button)
		else:
			var import_button = preload("res://Scenes/Editor/ImportSpriteButton.tscn").instance()
			import_button.text = "Replace Sprite"
			import_button.sprite_node = current_node
			add_button_font_colour_override(import_button, Color.red)
			buttons.add_child(import_button)

			var flip_h_button = preload("res://Scenes/Editor/FlipSpriteButton.tscn").instance()
			flip_h_button.text = "Flip Sprite Horizontally"
			if current_node.flip_h:
				flip_h_button.text += " (Flipped)"
			flip_h_button.sprite_node = current_node
			flip_h_button.flip_dir = "h"
			add_button_font_colour_override(flip_h_button, Color.hotpink)
			buttons.add_child(flip_h_button)

			var flip_v_button = preload("res://Scenes/Editor/FlipSpriteButton.tscn").instance()
			flip_v_button.text = "Flip Sprite Vertically"
			if current_node.flip_v:
				flip_v_button.text += " (Flipped)"
			flip_v_button.sprite_node = current_node
			flip_v_button.flip_dir = "v"
			add_button_font_colour_override(flip_v_button, Color.hotpink)
			buttons.add_child(flip_v_button)

	elif current_node is Node2D and current_node.name == "Ground":
		# Collision management buttons.
		for mat in ground_names:
			if not mat in ground_names_already_present:
				var button = preload("res://Scenes/Editor/AddCollisionTypeButton.tscn").instance()
				button.col_name = mat
				button.text = "Add new material: " + mat
				button.node = current_node
				button.col_type = "Ground"
				add_button_font_colour_override(button, Color.cornflower)
				buttons.add_child(button)

	elif current_node is Node2D and current_node.name == "Walls":
		# Collision management buttons.
		for mat in wall_names:
			if not mat in wall_names_already_present:
				var button = preload("res://Scenes/Editor/AddCollisionTypeButton.tscn").instance()
				button.col_name = mat
				button.text = "Add new material: " + mat
				button.node = current_node
				button.col_type = "Wall"
				add_button_font_colour_override(button, Color.brown)
				buttons.add_child(button)

	elif current_node is Node2D and current_node.name == "Checkpoints":
		# Collision management buttons.
		var button = preload("res://Scenes/Editor/AddCheckpointButton.tscn").instance()
		button.obj_name = str(highest_checkpoint_no + 1)
		button.text = "Add new checkpoint: Checkpoint " + str(button.obj_name)
		button.node = current_node
		add_button_font_colour_override(button, Color.yellow)
		buttons.add_child(button)

	elif current_node is Node2D and current_node.name == "Layers":
		# Collision management buttons.
		if highest_layer_no < max_layers - 1:
			var button = preload("res://Scenes/Editor/AddLayerButton.tscn").instance()
			button.obj_name = str(highest_layer_no + 1)
			button.text = "Add new layer: Layer " + str(button.obj_name)
			button.node = current_node
			add_button_font_colour_override(button, Color.blueviolet)
			buttons.add_child(button)
		else:
			var button = Button.new()
			button.text = "Max layers reached: " + str(max_layers)
			add_button_font_colour_override(button, Color.red)
			buttons.add_child(button)

	elif current_node is Area2D:
		# We are about to draw collision.
		shape.viewing = false

		if !shape.drawing:
			var button = preload("res://Scenes/Editor/AddCollisionButton.tscn").instance()
			button.text = "New Collision Shape"
			button.starting_collision_drawing = true
			add_button_font_colour_override(button, Color.darkcyan)
			buttons.add_child(button)
		else:
			var button = preload("res://Scenes/Editor/AddCollisionButton.tscn").instance()
			button.text = "Finish"
			button.starting_collision_drawing = false
			add_button_font_colour_override(button, Color.green)
			buttons.add_child(button)

	elif current_node is CollisionPolygon2D:
		shape.drawing = true
		for vertex in shape.get_children():
			shape.points[vertex] = vertex.rect_position

		# We have already made the polygon, so view until user selects "edit".
		shape.viewing = true

		tabs.set_tab_hidden(TabNames.OBJ, false)

		var set_name_button = preload("res://Scenes/Editor/RenameNodeButton.tscn").instance()
		set_name_button.text = "Set Name"
		set_name_button.node = current_node
		add_button_font_colour_override(set_name_button, Color.gold)
		buttons.add_child(set_name_button)

		var del_node_button = preload("res://Scenes/Editor/DeleteNodeButton.tscn").instance()
		del_node_button.text = "Delete"
		del_node_button.node = current_node
		add_button_font_colour_override(del_node_button, Color.red)
		buttons.add_child(del_node_button)

func _process(delta):
	cam_pos.text = "Camera Position: " + str(cam.position)
	cam_zoom.text = "Camera Zoom: " + str(cam.zoom.x) + "x"


func _on_CameraPosReset_pressed():
	cam.position = Vector2.ZERO


func _on_CameraZoomReset_pressed():
	cam.zoom = cam.DEFAULT_ZOOM


func _on_CameraPan_value_changed(value):
	current_pan = value
	cam_pan_label.text = "Camera Pan Speed: " + str(value)
	cam.speed = current_pan


func _on_CameraRotation_value_changed(value):
	cam.rotation_degrees = value
	cam_rot_label.text = "Camera Rotation: " + str(int(cam.rotation_degrees))


func _on_PixelPerfectButton_toggled(button_pressed):
	if button_pressed:
		cam.make_pixel_perfect()
	else:
		cam.pixel_perfect = false


func _on_PlayerFocusButton_toggled(button_pressed):
	if button_pressed:
		var player_cam = get_node_or_null("/root/Scene/Players/" + str(Global.PLAYER_ID) + "/Camera/Cam")
		if player_cam:
			player_cam.current = true
	else:
		cam.current = true


func _on_TabsToggleButton_toggled(button_pressed):
	if button_pressed:
		tabs.show()
	else:
		tabs.hide()


func _on_ShowAxesButton_toggled(button_pressed):
	if button_pressed:
		axes.show()
	else:
		axes.hide()
