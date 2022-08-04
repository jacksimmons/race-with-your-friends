extends Node

var mat_names = ["Concrete", "Tyre", "Grass", "Ice", "Sand", "Lava"]
var trig_names = ["Checkpoints", "Levels"]

var current_node: Node
onready var buttons = $Canvas/Buttons
onready var pan_speed_slider = $Canvas/PanSpeed/HSlider
onready var pan_speed_label = $Canvas/PanSpeed/Label
onready var cam_pos = $Canvas/CameraPos

onready var cam = $Camera/Camera2D
onready var shape = $Canvas/Shape


func _ready():
	current_node = $Map
	refresh_nodes()


func refresh_nodes():
	if $Display.get_child_count() > 0:
		for child in $Display.get_children():
			$Display.remove_child(child)
	var visible_node = current_node.duplicate()
	visible_node.visible = true
	visible_node.position = cam.get_parent().position # Place the node at the camera offset
	$Display.add_child(visible_node)
	
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
		var button = preload("res://Scenes/Editor/ImportSpriteButton.tscn").instance()
		button.text = "Import Sprite"
		button.sprite_node = current_node
		buttons.add_child(button)
	
	elif current_node is Node2D and current_node.name == "Collision":
		# Collision management buttons.
		for mat in mat_names:
			var button = preload("res://Scenes/Editor/AddCollisionTypeButton.tscn").instance()
			button.col_name = mat
			button.text = "Add new material: " + mat
			button.node = current_node
			button.col_type = "CollisionMaterial"
			buttons.add_child(button)
	
	elif current_node is Node2D and current_node.name == "Triggers":
		# Collision management buttons.
		for trig in trig_names:
			var button = preload("res://Scenes/Editor/AddCollisionTypeButton.tscn").instance()
			button.col_name = trig
			button.text = "Add new trigger type: " + trig
			button.node = current_node
			button.col_type = "TriggerType"
			buttons.add_child(button)
	
	elif current_node is Area2D:
		if !shape.drawing:
			var button = preload("res://Scenes/Editor/AddCollisionButton.tscn").instance()
			button.text = "Add new collision shape: Draw Vertices"
			button.starting_collision_drawing = true
			buttons.add_child(button)
		else:
			var button = preload("res://Scenes/Editor/AddCollisionButton.tscn").instance()
			button.text = "Finish"
			button.starting_collision_drawing = false
			buttons.add_child(button)
	
func _process(delta):
	pan_speed_label.text = "Camera Pan Speed: " + str(pan_speed_slider.value)
	cam.speed = pan_speed_slider.value
	
	cam_pos.text = "Camera Position: " + str(cam.position)


func _on_CameraPosReset_pressed():
	cam.position = Vector2.ZERO
