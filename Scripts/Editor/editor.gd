extends Node

var mat_names = ["Concrete", "Tyre", "Grass", "Ice", "Sand", "Lava"]
var trig_names = ["Checkpoints", "Levels"]

var current_node: Node
onready var buttons = $Canvas/Buttons
onready var pan_speed_slider = $Canvas/PanSpeed/HSlider
onready var pan_speed_label = $Canvas/PanSpeed/Label
onready var cam_pos = $Canvas/CameraPos

onready var display = $CamOffset/Display
onready var cam = $CamOffset/Camera2D
onready var shape = $Canvas/Shape


func _ready():
	current_node = $Map
	refresh_nodes()


func add_button_font_colour_override(button:Button, colour:Color):
	button.add_color_override("font_color", colour)
	button.add_color_override("font_color_disabled", colour)
	button.add_color_override("font_color_focus", colour)
	button.add_color_override("font_color_hover", colour)
	button.add_color_override("font_color_pressed", colour)


func refresh_nodes():
	if display.get_child_count() > 0:
		for child in display.get_children():
			display.remove_child(child)
	var visible_node = current_node.duplicate()
	visible_node.visible = true
	visible_node.position = cam.get_parent().position # Place the node at the camera offset
	display.add_child(visible_node)
	
	if buttons.get_child_count() > 0:
		for button in buttons.get_children():
			buttons.remove_child(button)
	
	if current_node.get_parent() != self:
		# If the node has a viewable parent...
		var current_parent = current_node.get_parent()
		var button = preload("res://Scenes/Editor/NodeChangeButton.tscn").instance()
		var button_text = "Back [" + current_parent.name + "]"
		button.in_scene = true
		button.node = current_parent
		button.text = button_text
		buttons.add_child(button)
		
	var children = current_node.get_children()
	for child in children:
		# Make all the buttons necessary to display all children.
		var button = preload("res://Scenes/Editor/NodeChangeButton.tscn").instance()
		var button_text = child.get_name()
		var child_count = child.get_child_count()
		if child_count > 0:
			button_text += " [" + str(child_count) + "]"
		button.in_scene = true
		button.node = child
		button.text = button_text
		buttons.add_child(button)
	
	if current_node is Sprite:
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
	
	elif current_node is Node2D and current_node.name == "Collision":
		# Collision management buttons.
		for mat in mat_names:
			var button = preload("res://Scenes/Editor/AddCollisionTypeButton.tscn").instance()
			button.col_name = mat
			button.text = "Add new material: " + mat
			button.node = current_node
			button.col_type = "CollisionMaterial"
			add_button_font_colour_override(button, Color.cornflower)
			buttons.add_child(button)
	
	elif current_node is Node2D and current_node.name == "Triggers":
		# Collision management buttons.
		for trig in trig_names:
			var button = preload("res://Scenes/Editor/AddCollisionTypeButton.tscn").instance()
			button.col_name = trig
			button.text = "Add new trigger type: " + trig
			button.node = current_node
			button.col_type = "TriggerType"
			add_button_font_colour_override(button, Color.yellow)
			buttons.add_child(button)
	
	elif current_node is Area2D:
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
			add_button_font_colour_override(button, Color.red)
			buttons.add_child(button)
	
	elif current_node is CollisionPolygon2D:
		
		
		var button = preload("res://Scenes/Editor/SetNameButton.tscn").instance()
		button.text = "Set Name"
		add_button_font_colour_override(button, Color.gold)
		buttons.add_child(button)
	
func _process(delta):
	pan_speed_label.text = "Camera Pan Speed: " + str(pan_speed_slider.value)
	cam.speed = pan_speed_slider.value
	
	cam_pos.text = "Camera Position: " + str(cam.position)


func _on_CameraPosReset_pressed():
	cam.position = Vector2.ZERO
