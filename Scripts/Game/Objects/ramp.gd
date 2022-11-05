extends Node2D

onready var layer0: Area2D = $"Layers/+0"
onready var layer1: Area2D = $"Layers/+1"
onready var collision: StaticBody2D = $Collision
onready var conveyor: Area2D = $ConveyorBelt

export (int) var starting_layer


func _ready():
	if starting_layer > Global.MAX_LAYER - 1:
		starting_layer = Global.MAX_LAYER - 1

	layer0.name = str(starting_layer)
	layer1.name = str(starting_layer + 1)
	collision.set_collision_layer_bit(31 - starting_layer, 1) # Layer (starting_layer)
	conveyor.set_layer(starting_layer + 1)
