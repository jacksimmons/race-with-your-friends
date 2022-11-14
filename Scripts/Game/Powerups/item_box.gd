extends Node2D

export (int, 0, 5) var value

const drops = {
	"First": {
		"Boost": 0.05,
		"Exhaust": 0.2,
		"Oil": 0.3,
		"Pigeon": 0.2,
		"Spikes": 0.2,
		"Spring": 0.05,
	},

	"Second": {
		"Boost": 0.1,
		"Exhaust": 0.05,
		"Grapple": 0.1,
		"Magpie": 0.3,
		"Oil": 0.15,
		"Pigeon": 0.1,
		"Spikes": 0.2
	},

	# 3-4
	"High": {
		"Boost": 0.2,
		"Grapple": 0.2,
		"Hippo": 0.1,
		"Magpie": 0.3,
		"Spikes": 0.2
	},

	# 5-7
	"Middle": {
		"Boost": 0.2,
		"Grapple": 0.2,
		"Hairdryer": 0.1,
		"Hippo": 0.25,
		"Magpie": 0.15,
		"Sock": 0.1
	},

	# 8-10
	"Low": {
		"Boost": 0.2,
		"Hippo": 0.3,
		"Sock": 0.2
	},

	"Second-Last": {
		"Rhino": 0.2,
		""
	},

	"Last": {
		"Rhino": 0.4,
	}
}


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


func _select_random_weight(weight_list):
	var total = 0
	for item in weight_list:
		pass


func _on_Area2D_body_entered(body):
	if body is Player:
		print(value)

	self.queue_free()
