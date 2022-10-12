extends HSlider

onready var val_lab = $"../NumRacesValue"

var lobby = null
var ready = false


func _ready():
	lobby = get_node_or_null("/root/Lobby")
	ready = true


func _on_NumRaces_value_changed(value):
	lobby.num_races = value
	val_lab.text = str(value)
