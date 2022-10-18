extends Node2D

var checkpoints = []
var last_checkpoint = 0
var count_lap = true
var lap = 1
var lap_count = 3

onready var players = $"/root/Scene/Players"
onready var race_debug = $"/root/Scene/Canvas/Race"
onready var lobby = $"/root/Lobby"


func _ready():
	for child in get_children():
		checkpoints.append(child)
	race_debug.get_node("CheckpointCount").text = "Checkpoint: 0/" + str(len(checkpoints) - 1)


func _process(delta):
	pass


func _on_cp_entered(body, cp_name):
	race_debug.get_node("CheckpointCount").text = "Checkpoint: " + cp_name + "/" + str(len(checkpoints) - 1)
	print("hi")
	if body is Player:
		body.cur_checkpoint = int(cp_name)

		if int(cp_name) < len(checkpoints) - 1:
			body.next_checkpoint = int(cp_name) + 1
		else:
			body.next_checkpoint = 0

		# Cases covered:
		# Last -> 0
		# a -> a + 1
		if int(cp_name) == 0:
			if body.lap_count == 0:
				# They have entered the first lap, i.e. lap 1, so...
				body.lap_count = 1
			else:
				# Handle lap counting normally
				if count_lap and int(last_checkpoint) == len(checkpoints) - 1:
					if lap < lap_count:
						lap += 1
					elif lap == lap_count:
						lobby.send_P2P_Packet("all", {"race_complete": true})
						var end = preload("res://Scenes/RaceEnd.tscn").instance()
						get_node("/root").add_child(end)
						self.queue_free()
				else:
					# Either player went 1 -> 0 or cheated this lap.
					# Don't count this lap, but count the next assuming player behaves.
					count_lap = true

		elif not int(cp_name) in range(int(last_checkpoint) - 1, int(last_checkpoint) + 1):
			# A checkpoint was skipped; don't count the lap
			count_lap = false

		print(range(int(last_checkpoint) - 1, int(last_checkpoint) + 1))
		race_debug.get_node("LapCount").text = "Lap: " + str(lap) + "/" + str(lap_count)
		last_checkpoint = cp_name
