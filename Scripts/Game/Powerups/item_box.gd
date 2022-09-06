extends Node2D

export (int, 0, 5) var value


const first_drops = [
	"Exhaust",
	"Spikes",
	"Boost",
	"Oil",
	"Spring",
	"Pigeon"
]

const high_drops = [
	"Boost",
	"Grapple",
	"Hippo",
	"Oil",
	"Spring",
	"Spikes",
	"Exhaust",
	"Pigeon",
	"Magpie"
]

const middle_drops = [
	"Boost",
	"Big Boost",
	"Eagle",
	"Grapple",
	"Hippo",
	"Oil",
	"Spring"
]

const back_drops = [
	"Big Boost",
	""
]


const level_1_drop_chances = {

	"Exhaust": 0.1,
	"Boost": 0.1,
	"Spring": 0.1,
	"Hippo": 0.05,
}


func _select_random_weight(weight_list):
	var total = 0
	for item in weight_list:
		pass



func _on_Area2D_body_entered(body):
	if body is Player:
		print(value)

	self.queue_free()
