extends Node


# Nodes
var lobby: Node


# Signals
signal host_status_update
signal vehicle_update
signal player_list_update
signal lobby_message


# Misc. Variables
var time := 0


# Network Variables
var PACKET_READ_LIMIT = 250
var NETWORK_REFRESH_INTERVAL = 0.1


# Steam Variables
var OWNED := false
var ONLINE := false
var STEAM_ID := 0
var STEAM_NAME := ""


# Lobby Variables
var MAX_MEMBERS := 12
var MAX_LOBBY_RESULTS := 50

var lobby_id := 0
var lobby_members := []
var lobby_invite_arg := false

var host := false
var join_type: int
var num_races: int

var selected_map := ""
var final_readier := false
var local_pre_config_done := false


# Game Variables
var game_mode: int
var game_started := false

var player_data := {}
var bot_data := {}
var num_checkpoints := 0
var blacklist := []

var my_player: Player
var my_starting_pos: int

var lerps := {}
var position_last_update: Vector2
var rotation_last_update: float

var in_game_ranking: Array = []
var final_ranking: Array = []
var race_finished: bool = false
var roster_size_after_race: int
var roster_update_after_race: bool = false


# Enums
enum GameMode { SINGLE, MULTI, EDITOR }
enum SendType {Unreliable, UnreliableNoDelay, Reliable, ReliableNoDelay}
enum LeaveReason { NONE, KICKED, BANNED }
enum JoinType {Private, Friends, Public, Invisible}
enum SearchDistance {Close, Default, Far, Worldwide}
enum SortCondition { LAP, POSITION }
enum Fullness {Any, Empty, Full}
enum LobbyComparison {LTE = -2, LT = -1, E = 0, GT = 1, GTE = 2, NE = 3}


# Processing functions
func _ready():
	# Initialise steam
	var INIT := Steam.steamInit()

	if INIT["status"] != 1:
		# E.g. If user tries to load the game without being signed into Steam
		print("Failed to initialise Steam. " + str(INIT["verbal"]) + " Shutting down...")
		get_tree().quit()

	ONLINE = Steam.loggedOn()
	STEAM_ID = Steam.getSteamID()

	STEAM_NAME = Steam.getPersonaName()

	print("STEAMID: " + str(STEAM_ID))
	print("STEAMNAME: " + str(STEAM_NAME))

	OWNED = Steam.isSubscribed()

	if !OWNED:
		print("User doesn't own this game.")
		get_tree().quit()

	# Steam callbacks
	Steam.connect("lobby_created", self, "_on_Lobby_Created")
	Steam.connect("lobby_joined", self, "_on_Lobby_Joined")
	Steam.connect("lobby_chat_update", self, "_on_Lobby_Chat_Update")
	Steam.connect("lobby_message", self, "_on_Lobby_Message")
	Steam.connect("lobby_data_update", self, "_on_Lobby_Data_Update")
	Steam.connect("lobby_invite", self, "_on_Lobby_Invite")
	Steam.connect("join_requested", self, "_on_Lobby_Join_Requested")
	Steam.connect("persona_state_change", self, "_on_Persona_Change")
	Steam.connect("p2p_session_request", self, "_on_P2P_Session_Request")
	Steam.connect("p2p_session_connect_fail", self, "_on_P2P_Session_Connect_Fail")

	#Check for command-line arguments
	check_Command_Line()


func _process(delta):
	Steam.run_callbacks()

	# If the player is connected, read packets
	if lobby_id != 0:
		read_All_P2P_Packets()

	if game_started:
		time += delta / NETWORK_REFRESH_INTERVAL
		if time >= delta:
			time = 0
			if my_player.position != position_last_update:
				# Send updated position
				send_P2P_Packet("all", {"position": my_player.position})
				position_last_update = my_player.position
				# Also send updated path position
				var dist = my_player.get_dist_from_next_checkpoint()
				send_P2P_Packet("all", {"checkpoint_position": {
					"lap": my_player.lap_count,
					"checkpoint": my_player.cur_checkpoint,
					"distance": dist
					}})
			if my_player.rotation != rotation_last_update:
				send_P2P_Packet("all", {"rotation": my_player.rotation})
				rotation_last_update = my_player.rotation

	else:
		time += delta / 10
		if time >= delta:
			time = 0


func _physics_process(delta):
	for player_id in lerps:
		var player = get_node("/root/Scene/Players/" + str(player_id))
		if lerps[player_id].has("position"):
			player.position = lerp(player.position, lerps[player_id]["position"], 0.2)

			if player.position.is_equal_approx(lerps[player_id]["position"]):
				lerps[player_id].erase("position")

		if lerps[player_id].has("rotation"):
			player.rotation = lerp_angle(player.rotation, lerps[player_id]["rotation"], 0.2)

			if is_equal_approx(player.rotation, lerps[player_id]["rotation"]):
				lerps[player_id].erase("rotation")

		# Needs to be at the end of this loop (cascading)
		if lerps[player_id] == {}:
			lerps.erase(player_id)


# Command Line Checking
func check_Command_Line():
	var ARGUMENTS = OS.get_cmdline_args()

	# Check if detected arguments
	if ARGUMENTS.size() > 0:
		for arg in ARGUMENTS:
			# Invite arg passed
			if lobby_invite_arg:
				join_Lobby(int(arg))

			# Steam connection arg
			if arg == "+connect_lobby":
				lobby_invite_arg = true


# Lobby functions
func get_lobby_data(key: String):
	# Implementation function to reduce other scripts' usage of Steam library
	return Steam.getLobbyData(lobby_id, key)

## Packets
func read_P2P_Packet():
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	var channel: int = 0

	# If there is a packet
	if packet_size > 0:
		var packet: Dictionary = Steam.readP2PPacket(packet_size, channel)

		if packet.empty() or packet == null:
			print("WARNING: Read an empty packet with non-zero size!")

		# Get the remote user's ID
		var packet_sender: int = packet["steam_id_remote"]

		# Make the packet readable
		var packet_code: PoolByteArray = packet["data"]
		var readable: Dictionary = bytes2var(packet_code)

		# Print the packet to output
		print("Packet: " + str(readable))

		# Deal with packet data below

		## Lobby
		# a "message" packet.
		if readable.has("message"):
			# Handshake - we send all our data with the newcomer.
			if readable["message"] == "handshake":
				# If they are banned...
				if host and packet_sender in blacklist:
					send_P2P_Packet(str(packet_sender), {"banned": true})
				else:
					var their_data = player_data[STEAM_ID]
					if their_data.has("vehicle"):
						send_P2P_Packet(str(packet_sender), {"vehicle": their_data["vehicle"]})
					if their_data.has("ready"):
						send_P2P_Packet(str(packet_sender), {"ready": their_data["ready"]})

		if readable.has("set_host"):
			if lobby_id != 0:
				# We have been given host, or had host taken away from us (somehow).
				set_host_status(readable["set_host"])

		if readable.has("host_obtained"):
			if lobby_id != 0:
				# The new host has received our request to give them host; we
				# now need to provide them with any data the host needs.
				player_data[packet_sender]["host"] = true
				if host:
					var host_data = {}
					host_data["join_type"] = join_type
					host_data["num_races"] = num_races
					send_P2P_Packet(str(packet_sender), {"host_data": host_data})

		if readable.has("host_data"):
			if lobby_id != 0:
				# We have received the data from the previous host, and must
				# interpret it and store it.
				var host_data = readable["host_data"]
				join_type = host_data["join_type"]
				num_races = host_data["num_races"]
				send_P2P_Packet(str(packet_sender), {"host_ack": true})

		if readable.has("host_ack"):
			if lobby_id != 0:
				# Our job as host is done, and we now retire host privileges.
				set_host_status(false)

		if readable.has("kicked"):
			if readable["kicked"]:
				if lobby_id != 0 and !host:
					exit_to_main(LeaveReason.KICKED)

		if readable.has("banned"):
			if readable["banned"]:
				if lobby_id != 0 and !host:
					exit_to_main(LeaveReason.BANNED)

		# a "vehicle" packet.
		if readable.has("vehicle"):
			player_data[packet_sender]["vehicle"] = readable["vehicle"]

		if readable.has("map_vote"):
			player_data[packet_sender]["map_vote"] = readable["map_vote"]

		# a "ready" packet. Can assume a steam_id will be provided
		# Note: It is up to the final readier to send an "all_ready" packet.
		if readable.has("ready"):
			player_data[packet_sender]["ready"] = readable["ready"]
			update_lobby_members()

		# a "pre_config_complete" packet. Can assume a steam_id will be provided
		# The players pre config one after the other to ensure we can control data in a non-chaotic way.
		# Note: It is up to the final readier to send an "all_pre_configs_complete" message packet.
		if readable.has("pre_config_complete"):
			# If we haven't already preloaded, we can preload.
			var gets_to_pre_load = false
			if !player_data[STEAM_ID].has("pre_config_complete"):
				gets_to_pre_load = true
			elif !player_data[STEAM_ID]["pre_config_complete"]:
				gets_to_pre_load = true

			if gets_to_pre_load:
				player_data[packet_sender]["pre_config_complete"] = true

				if readable["pre_config_complete"].has("map"):
					# Get the randomly selected map from the person who just readied up
					selected_map = readable["pre_config_complete"]["map"]

				# Our turn to handle preconfig
				start_pre_config()

				# Check if all preconfigs are complete, and if so, send an "all_pre_configs_complete" packet.
				var all_pre_configs_complete = true
				var ids = player_data.keys()

				for player_id in ids:
					if player_data[player_id].has("pre_config_complete"):
						if player_data[player_id]["pre_config_complete"]:
							continue
						else:
							all_pre_configs_complete = false
							break
					else:
						all_pre_configs_complete = false
						break

				if all_pre_configs_complete:
					send_P2P_Packet("all", {"all_pre_configs_complete": true})
					print("All pre configs complete.")
					load_game()

		if readable.has("all_pre_configs_complete"):
			if readable["all_pre_configs_complete"]:
				load_game()

		# a "bot_vehicle" packet. Will be sent by the host to all clients. Is a Dictionary object.
		if readable.has("bot_vehicle"):
			var bot_vehicle: Dictionary = readable["bot_vehicle"]
			if !bot_vehicle["name"] in bot_data:
				bot_data[bot_vehicle["name"]] = {"vehicle": bot_vehicle["vehicle"]}
			else:
				bot_data[bot_vehicle["name"]]["vehicle"] = bot_vehicle["vehicle"]

			if bot_data.size() == MAX_MEMBERS - player_data.size():
				start_bot_config(name)

		## In-Game
		# a "position" packet.
		if readable.has("position"):
			if packet_sender != STEAM_ID:
				# We don't want to update our correct position with the network's estimated position
				var player = get_node("/root/Scene/Players/" + str(packet_sender))

				if !lerps.has(packet_sender):
					lerps[packet_sender] = {}
				lerps[packet_sender]["position"] = readable["position"]

		# a "rotation" packet.
		if readable.has("rotation"):
			if packet_sender != STEAM_ID:
				# We don't want to update our correct rotation with the network's estimated rotation
				var player = get_node("/root/Scene/Players/" + str(packet_sender))

				if !lerps.has(packet_sender):
					lerps[packet_sender] = {}
				lerps[packet_sender]["rotation"] = readable["rotation"]

		if readable.has("checkpoint_position"):
			# This is a very "local resource" heavy packet to handle
			if packet_sender != STEAM_ID:
				# This assumes the list without this ranking is ranked,
				# which it is as every new ranking is insertion-sorted.
				var lap = readable["lap"]
				var cp = readable["checkpoint"]
				var dist = readable["distance"]
				var provided_ranking = {
					"lap": lap,
					"checkpoint": cp,
					"distance": dist,
					"id": packet_sender
					}
				for ranking in in_game_ranking:
					# If they are on a lower lap than this ranking, they
					# must be inserted further along the list.
					if lap < ranking["lap"]:
						continue

					# If the laps are equal, we need to compare checkpoints...
					elif lap == ranking["lap"]:
						# If they are on a lower cp than this ranking, they
						# must be inserted further along the list.
						if cp < ranking["checkpoint"]:
							continue
						# If the cps are equal, we need to compare dists.
						elif cp == ranking["checkpoint"]:
							# If they are on a higher distance, they must be inserted
							# further along the list.
							if dist > ranking["distance"]:
								continue
							# If the distances are equal, insert them after the ranking.
							elif dist == ranking["distance"]:
								var index = in_game_ranking.find(ranking)
								Global.slot_in(provided_ranking, in_game_ranking, index)
							# If they are on a lower distance, insert them before.
							else:
								var index = in_game_ranking.find(ranking) - 1
								Global.slot_in(provided_ranking, in_game_ranking, index)
						# If they are on a higher cp than this ranking, they
						# must be inserted before in this list.
						else:
							var index = in_game_ranking.find(ranking) - 1
							Global.slot_in(provided_ranking, in_game_ranking, index)

					# If they are on a higher lap than this ranking, they must be
					# inserted before in this list.
					else:
						var index = in_game_ranking.find(ranking) - 1
						Global.slot_in(provided_ranking, in_game_ranking, index)

				for ranking in in_game_ranking:
					if ranking["id"] == STEAM_ID:
						my_player.race_placement = in_game_ranking.find(ranking)


		if readable.has("race_complete"):
			if readable["race_complete"]:
				final_ranking.append(packet_sender)

		if readable.has("all_race_complete"):
			if readable["all_race_complete"]:
				finish_game()

		if readable.has("roster_size_after_race"):
			roster_size_after_race = readable["roster_size_after_race"]


func read_All_P2P_Packets(read_count: int = 0):
	# Recursively reads all packets
	if read_count >= PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_P2P_Packet()
		read_All_P2P_Packets(read_count + 1)


func send_P2P_Packet(target: String, packet_data: Dictionary) -> void:
	# Assign SendType and channel
	var send_type: int = SendType.Reliable
	var channel: int = 0

	# Create a data array to send the data through
	var data: PoolByteArray
	data.append_array(var2bytes(packet_data))

	# If sending a packet to everyone
	if target == "all":
		# If there is more than one user, send packets
		if lobby_members.size() > 1:
			# Loop through all members that aren't you
			for member in lobby_members:
				if member['steam_id'] != STEAM_ID:
					Steam.sendP2PPacket(member['steam_id'], data, send_type, channel)

	# Else sending it to someone specific
	else:
		Steam.sendP2PPacket(int(target), data, send_type, channel)


func make_P2P_Handshake() -> void:
	# Sends a P2P handshake to the lobby
	send_P2P_Packet("all", {"message": "handshake"})


## Interactions
func set_host_status(set_host: bool) -> void:
	host = set_host

	if lobby and !game_started:
		emit_signal("host_update", host)

	if host:
		send_P2P_Packet("all", {"host_obtained": true})


func update_lobby_members() -> void:
	# Clear prev. lobby members list
	lobby_members.clear()

	# Get number of members in lobby
	var member_count = Steam.getNumLobbyMembers(lobby_id)

	if race_finished:
		if member_count != roster_size_after_race:
			roster_update_after_race = true

	# Get members data
	for member in range(0, member_count):
		# Member's Steam ID
		var member_steam_id = Steam.getLobbyMemberByIndex(lobby_id, member)
		# Member's Steam Name
		var member_steam_name = Steam.getFriendPersonaName(member_steam_id)
		# Add members to list
		add_player_to_list(member_steam_id, member_steam_name)


func send_Chat_Message(message: String) -> void:
	# If the message is non-empty
	if message.length() > 0:
		# Pass message to Steam
		var SENT: bool = Steam.sendLobbyChatMsg(lobby_id, message)

		# Check message sent
		if !SENT and !game_started:
			lobby.display_message("ERROR: Chat message failed to send.")


## Status
func create_Lobby() -> void:
	# Check no other lobbies are running
	if lobby_id == 0:
		Steam.createLobby(join_type, MAX_MEMBERS)
		player_data[STEAM_ID] = {}
		player_data[STEAM_ID]["start_position"] = 0
	set_host_status(true)


func join_Lobby(lobby_id) -> void:
	# Gets value of the "name" key with provided lobby_id
	var name = Steam.getLobbyData(lobby_id, "name")

	# Clear prev. lobby members lists
	lobby_members.clear()

	# Load lobby scene
	var loaded_lobby = preload("res://Scenes/LobbyMulti.tscn").instance()
	get_node("/root").add_child(loaded_lobby)

	# Steam join request
	Steam.joinLobby(lobby_id)


func leave_Lobby() -> void:
	# If we are in a lobby, leave it.
	if lobby_id != 0:
		if lobby and !game_started:
			lobby.display_message("Leaving lobby...")

		# Reset host status first, if we are host
		if len(player_data) > 1 and host:
			# If there is someone else to give host to, give it to the first
			# person who joined (excluding us).
			send_P2P_Packet(player_data[0], {"set_host": true})

		# Send leave request
		Steam.leaveLobby(lobby_id)

		# Wipe Lobby ID (to show we aren't in a lobby anymore)
		lobby_id = 0

		# Close any possible sessions with other users
		for member in lobby_members:
			Steam.closeP2PSessionWithUser(member["steam_id"])

		# Clear lobby list
		lobby_members.clear()

		#player_count.text = "Players: 0"
		# Empty the playerlist
		#for child in playerList.get_children():
		#	child.queue_free()


func add_player_to_list(steam_id, steam_name) -> void:
	# Add players to list
	lobby_members.append({"steam_id" : steam_id, "steam_name" : steam_name})

	if lobby and !game_started:
		emit_signal("player_list_update", lobby_members)


# Misc.
func exit_to_main(leave_reason: int):
	var scene = preload("res://Scenes/MenuTitle.tscn").instance()
	get_node("/root").add_child(scene)
	match leave_reason:
		LeaveReason.KICKED:
			var accept_dialog = scene.get_node("AcceptDialog")
			accept_dialog.dialog_text = "You have been kicked from " + Steam.getLobbyData(lobby_id, "name")
			accept_dialog.popup()
		LeaveReason.BANNED:
			var accept_dialog = scene.get_node("AcceptDialog")
			accept_dialog.dialog_text = "You have been banned from " + Steam.getLobbyData(lobby_id, "name")
			accept_dialog.popup()
	leave_Lobby()
	self.queue_free()


func lobby_screen_entered():
	lobby = $"/root/Lobby"
	lobby.connect("vehicle_selected", self, "_on_vehicle_selected")
	lobby.connect("map_selected", self, "_on_map_selected")
	lobby.connect("player_ready", self, "_on_player_ready")


# Game Setup
func setup_scene(map, race_pos):
	# Sets up a game scene using Global and Game data.
	var my_id = STEAM_ID

	# Add scene to root
	get_node("/root").add_child(map)

	var checkpoints = map.get_node("Checkpoints")

	num_checkpoints = checkpoints.get_child_count()

	# Load my Player and Camera
	var vehicle = player_data[my_id]["vehicle"]
	my_player = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()

	my_player.set_name(str(my_id))
	var players = get_node("/root/Scene/Players")
	var start_point = map.get_node("StartPoints").get_node(str(race_pos))
	var point_f = start_point.to_global(start_point.get_node("Front").position)
	var point_b = start_point.to_global(start_point.get_node("Back").position)
	my_player.position = ((point_f + point_b) / 2)
	my_player.position.x -= my_player.get_node("VehicleSprite").get_texture().get_height() / 2
	players.add_child(my_player)

	var my_cam = preload("res://Scenes/Cam.tscn").instance()
	my_cam.name = "CAM_" + str(my_id)
	my_player.add_child(my_cam)

	if game_mode == GameMode.SINGLE:
		pass

	elif game_mode == GameMode.MULTI:
		var ids = Server.player_data.keys()
		var num_players = len(ids)

		for player_id in ids:
			if int(player_id) != my_id:
				var friend_vehicle = Server.player_data[player_id]["vehicle"]
				var friend = load("res://Scenes/Vehicles/" + friend_vehicle + ".tscn").instance()
				friend.set_name(str(player_id))
				players.add_child(friend)

				var cam = preload("res://Scenes/Cam.tscn").instance()
				cam.set_name("CAM_" + str(player_id))
				friend.add_child(cam)

	player_data[my_id]["pre_config_complete"] = true


func setup_bot(id, map, race_pos):
	# Sets up a game scene using Global and Game data.
	var my_id = bot_data

	# Add scene to root
	get_node("/root").add_child(map)

	var checkpoints = map.get_node("Checkpoints")

	num_checkpoints = checkpoints.get_child_count()

	# Load my Player and Camera
	var vehicle = player_data[my_id]["vehicle"]
	my_player = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()

	my_player.set_name(str(my_id))
	var players = get_node("/root/Scene/Players")
	var start_point = map.get_node("StartPoints").get_node(str(race_pos))
	var point_f = start_point.to_global(start_point.get_node("Front").position)
	var point_b = start_point.to_global(start_point.get_node("Back").position)
	my_player.position = ((point_f + point_b) / 2)
	my_player.position.x -= my_player.get_node("VehicleSprite").get_texture().get_height() / 2
	players.add_child(my_player)

	var my_cam = preload("res://Scenes/Cam.tscn").instance()
	my_cam.name = "CAM_" + str(my_id)
	my_player.add_child(my_cam)

	if game_mode == GameMode.SINGLE:
		pass

	elif game_mode == GameMode.MULTI:
		var ids = Server.player_data.keys()
		var num_players = len(ids)

		for player_id in ids:
			if int(player_id) != my_id:
				var friend_vehicle = Server.player_data[player_id]["vehicle"]
				var friend = load("res://Scenes/Vehicles/" + friend_vehicle + ".tscn").instance()
				friend.set_name(str(player_id))
				players.add_child(friend)

				var cam = preload("res://Scenes/Cam.tscn").instance()
				cam.set_name("CAM_" + str(player_id))
				friend.add_child(cam)

	player_data[my_id]["pre_config_complete"] = true


func _on_player_ready():
	if lobby_id != 0:
		var all_ready = true

		# Random selections if selections haven't been made
		if !player_data[STEAM_ID].has("vehicle"):
			var vehicle = Global.get_random_scene(Global.SceneType.VEHICLE)
			player_data[STEAM_ID]["vehicle"] = vehicle
			send_P2P_Packet("all", {"vehicle": vehicle})
		if !player_data[STEAM_ID].has("map_vote"):
			var map = Global.get_random_scene(Global.SceneType.MAP)
			player_data[STEAM_ID]["map_vote"] = map
			send_P2P_Packet("all", {"map_vote": map})

		# Toggle readiness if present, or activate it if not
		if player_data[STEAM_ID].has("ready"):
			var ready = player_data[STEAM_ID]["ready"]
			send_P2P_Packet("all", {"ready": !ready})
			player_data[STEAM_ID]["ready"] = !ready
			# Refresh the lobby as your readiness has changed.
			update_lobby_members()
		else:
			send_P2P_Packet("all", {"ready": true})
			player_data[STEAM_ID]["ready"] = true
			# Refresh the lobby as your readiness has changed.
			update_lobby_members()

		# Check if last to ready up - this means I am the "all_ready" starter
		for player_id in player_data:
			if player_data[player_id].has("ready"):
				if player_data[player_id].has("vehicle"):
					if player_data[player_id]["ready"]:
						continue
					else:
						all_ready = false
						break
				else:
					all_ready = false
					break
			else:
				all_ready = false
				break

		if all_ready:
			# Secretly start the preconfig process, then after completing it, notify the others one by one.
			final_readier = true
			start_pre_config()


func start_pre_config() -> void:
	# Initially, only run by the last player to ready up. Then the others are notified in order and they each call this.
	get_tree().set_pause(true)

	if final_readier:
		var map_votes = []
		for player_id in player_data:
			map_votes.append(player_data[player_id]["map_vote"])
		selected_map = Global.get_random_arrayitem(map_votes)

	if !local_pre_config_done:
		var map = load("res://Scenes/Maps/" + selected_map + ".tscn").instance()
		game_mode = GameMode.MULTI
		setup_scene(map, 12)

		local_pre_config_done = true

		if final_readier:
			send_P2P_Packet("all", {"pre_config_complete": {"map": selected_map}})
		else:
			send_P2P_Packet("all", {"pre_config_complete": true})

	var ids = player_data.keys()
	var num_players = len(ids)
	var num_bots = 0 #MAX_MEMBERS - num_players

	if host:
		for i in range(num_bots):
			var name = "BOT" + str(i)
			var vehicle = Global.get_random_scene(Global.SceneType.VEHICLE)
			if !(name in bot_data):
				bot_data[name] = {"vehicle": vehicle}
			else:
				bot_data[name]["vehicle"] = vehicle
			send_P2P_Packet("all", {"bot_vehicle": {"name": "BOT" + str(i), "vehicle": vehicle}})
			start_bot_config("BOT" + str(i))
	player_data[STEAM_ID]["pre_config_complete"] = true
	get_tree().set_pause(false)


func start_bot_config(id) -> void:
	get_tree().set_pause(true)

	var map = load("res://Scenes/Maps/" + selected_map + ".tscn").instance()
	setup_bot(id, map, bot_data[id]["start_pos"])

	bot_data[id]["pre_config_complete"] = true
	get_tree().set_pause(false)


func _on_vehicle_selected(vehicle: String):
	if lobby_id != 0:
		send_P2P_Packet("all", {"vehicle": vehicle})
		player_data[STEAM_ID]["vehicle"] = vehicle

		# This selection has no effect unless we're in the lobby
		if lobby and !game_started:
			emit_signal("vehicle_update", vehicle)


func _on_map_selected(map: String):
	if lobby_id != 0:
		send_P2P_Packet("all", {"map_vote": map})
		player_data[STEAM_ID]["map_vote"] = map


func load_game() -> void:
	# Properly loads the game.
	get_tree().set_pause(true)
	start_game()
	get_tree().set_pause(false)


func start_game() -> void:
	# ! Need to set this to false whenever it ends.
	game_started = true


func finish_game() -> void:
	race_finished = true


func _on_i_finished() -> void:
	send_P2P_Packet("all", {"race_complete": true})
	#var end = preload("res://Scenes/RaceEnd.tscn").instance()
	#get_node("/root").add_child(end)

	if lobby_id != 0:
		var all_complete = true

		# Check if last to complete - last place sends a packet
		for player_id in player_data:
			if player_data[player_id].has("race_complete"):
				if !player_data[player_id]["race_complete"]:
					all_complete = false
			else:
				all_complete = false

		if all_complete:
			send_P2P_Packet("all", {"all_race_complete": true})
			send_P2P_Packet("all", {"roster_size_after_race": player_data.size()})
			finish_game()


# Steam Callbacks
func _on_Lobby_Join_Requested(lobby_id, friend_id) -> void:
	# Callback occurs when attempting to join via Steam overlay

	# Get lobby owner's name
	var owner_name = Steam.getFriendPersonaName(friend_id)

	# Join the lobby
	join_Lobby(lobby_id)


func _on_Lobby_Created(connect, lobbyID):
	if connect == 1:
		# Set Lobby ID
		lobby_id = lobbyID

		var lobby_name = "Lobby of " + STEAM_NAME

		if lobby and !game_started:
			lobby.display_message("Created lobby: " + lobby_name)

		# Make it joinable (this should be done by default anyway)
		Steam.setLobbyJoinable(lobbyID, true)

		# Set Lobby Data - this is custom data, I need to do this manually.
		Steam.setLobbyData(lobbyID, "name", lobby_name)
		Steam.setLobbyData(lobbyID, "type", JoinType.keys()[join_type])

		Steam.setLobbyMemberLimit(lobbyID, MAX_MEMBERS)

		var RELAY = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: " + str(RELAY))


func _on_Lobby_Joined(lobbyID, perms, locked, response) -> void:
	# Success
	if response == 1:
		# Set lobby ID
		lobby_id = lobbyID

		# Get lobby name
		var name = Steam.getLobbyData(lobbyID, "name")

		# Get lobby members
		update_lobby_members()

		# Make the initial handshake
		make_P2P_Handshake()

	# Failure
	else:
		var FAIL_REASON: String

		match response:
			2:	FAIL_REASON = "This lobby no longer exists."
			3:	FAIL_REASON = "You don't have permission to join this lobby."
			4:	FAIL_REASON = "The lobby is now full."
			5:	FAIL_REASON = "Uh... something unexpected happened!"
			6:	FAIL_REASON = "You are banned from this lobby."
			7:	FAIL_REASON = "You cannot join due to having a limited account."
			8:	FAIL_REASON = "This lobby is locked or disabled."
			9:	FAIL_REASON = "This lobby is community locked."
			10:	FAIL_REASON = "A user in the lobby has blocked you from joining."
			11:	FAIL_REASON = "A user you have blocked is in the lobby."

		# Reopen the lobby list
		print("Fail: " + FAIL_REASON)


func _on_Lobby_Data_Update(success, lobbyID, memberID, key=null) -> void:
	# Will complain if this callback is not handled
	print("Success: "+str(success)+", Lobby ID: "+str(lobbyID)+", Member ID: "+str(memberID)+", Key: "+str(key))


func _on_Lobby_Chat_Update(lobbyID, changedID, changeMakerID, chatState) -> void:
	# The user who made the lobby change
	var CHANGER = Steam.getFriendPersonaName(changeMakerID)

	# chatState change made
	if lobby and !game_started:
		if chatState == 1:
			lobby.display_message(str(CHANGER) + " has joined the lobby.")
		elif chatState == 2:
			lobby.display_message(str(CHANGER) + " has left the lobby.")
		elif chatState == 4:
			lobby.display_message(str(CHANGER) + " has disconnected from the lobby.")
		elif chatState == 8:
			lobby.display_message(str(CHANGER) + " has been kicked from the lobby.")
		elif chatState == 16:
			lobby.display_message(str(CHANGER) + " has been banned the lobby.")
		else:
			lobby.display_message(str(CHANGER) + " did... something.")

	# Update lobby
	update_lobby_members()


func _on_Lobby_Invite():
	pass


func _on_Persona_Change(steam_id: int, flag: int) -> void:
	if lobby and !game_started:
		# A user has had an info change; update the lobby list
		lobby.display_message("Persona change has occurred, lobby list will now refresh.")

	# Update the lobby list
	update_lobby_members()


func _on_P2P_Session_Request(remoteID: int) -> void:
	# Get the requester's name
	var REQUESTER: String = Steam.getFriendPersonaName(remoteID)

	# Accept the P2P session request
	Steam.acceptP2PSessionWithUser(remoteID)

	# Initial handshake
	make_P2P_Handshake()


func _on_P2P_Session_Connect_Fail(steamID: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with "+str(steamID)+" [no error given].")

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with "+str(steamID)+" [target user not running the same game].")

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with "+str(steamID)+" [local user doesn't own app / game].")

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with "+str(steamID)+" [target user isn't connected to Steam].")

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with "+str(steamID)+" [connection timed out].")

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with "+str(steamID)+" [unused].")

	# Else no known error
	else:
		print("WARNING: Session failure with "+str(steamID)+" [unknown error "+str(session_error)+"].")
