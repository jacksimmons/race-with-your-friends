extends Node


onready var lobby = $"../../../../../"


signal vehicle_button_pressed(vehicle)


func _ready():
	connect("button_down", self, "_on_pressed")
	connect("vehicle_button_pressed", lobby, "_on_Vehicle_Selected")
	connect("vehicle_button_pressed", get_parent(), "_on_Button_Pressed")


func _on_pressed():
	emit_signal("vehicle_button_pressed", get_child(0).name)
