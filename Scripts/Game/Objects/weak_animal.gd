extends "res://Scripts/Game/Objects/routed_obj.gd"

onready var sprite: Sprite = $Sprite


func _handle_collision(col):
	var tex = preload("res://Sprites/Objects/BloodSplat.png")
	sprite.set_texture(tex)
	die()
