extends Control

# Enum
enum JoinType {Private, Friends, Public, Invisible}
enum SearchDistance {Close, Default, Far, Worldwide}
enum SendType {Unreliable, UnreliableNoDelay, Reliable, ReliableNoDelay}
enum SortCondition { LAP, POSITION }
enum LeaveReason { NONE, KICKED, BANNED }
enum Fullness {Any, Empty, Full}
enum LobbyComparison {LTE = -2, LT = -1, E = 0, GT = 1, GTE = 2, NE = 3}

# Onreadies
onready var lobbySetName = $Settings/Popup/LobbyNameEdit
onready var lobbySettings = $Settings/LobbySettingsButton
onready var lobbySettingsPopup = $Settings/Popup

onready var chatInput = $Chat/TextEdit
onready var chatOutput = $Chat/MessageList

onready var playerCount = $Players/NoOfPlayers
onready var playerList = $Players/PlayerList

onready var texButton = $Players/TextureButton

onready var chatInputButton = $Chat/SendMessageButton

onready var cam = $Camera2D

# Lobby

# Host data (add to HOST_DATA)
var join_type: int = JoinType.Public
var num_races: int = 1
# End host data

var cam_on_stats: bool = false
var cam_on_lobby: bool = false
var position_for_cam_on_stats := Vector2(-1920, 0)
var position_for_cam_on_lobby := Vector2(0, 0)

var host: bool = false

var message_input_shown: bool = false

var all_ready: bool = false
var all_pre_configs_complete: bool = false
var local_pre_config_done: bool = false

var final_readier = false
var selected_map: String

# Game
var time: float = 0
var my_player = null
var position_last_update: Vector2 = Vector2.ZERO
var rotation_last_update: int = 0
var race_position_last_update: Dictionary = {}

var lerps: Dictionary = {}


func _ready():
	# Steamwork Connections
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

	#Place vehicle sprite in the correct position
	fix_vehicle_sprite()

	#Check for command-line arguments
	Game.check_Command_Line()


func _process(delta):
	# If the player is connected, read packets
	if Game.LOBBY_ID != 0:
		read_All_P2P_Packets()

	if Game.GAME_STARTED:
		time += delta / Game.NETWORK_REFRESH_INTERVAL
		if time >= delta:
			time = 0
			if my_player.position != position_last_update:
				send_P2P_Packet("all", {"position": my_player.position})
				position_last_update = my_player.position
			if my_player.rotation != rotation_last_update:
				send_P2P_Packet("all", {"rotation": my_player.rotation})
				rotation_last_update = my_player.rotation

			# Race placements (to be done by host only)
			"""if false and host:
				var ordered_positions = []
				for player_id in Game.PLAYER_DATA:
					var player = get_node("/root/Scene/Players/" + str(player_id)) as Player
					var lap = player.lap_count
					var pos = player._get_race_position()

					if ordered_positions.empty():
						ordered_positions.append({"lap": lap, "pos": pos, "id": player_id})
					else:
						var lap_placed = false
						var pos_placed = false
						var dict = {"lap": lap, "pos": pos}

						ordered_positions = _sort_positions(SortCondition.LAP, ordered_positions, dict)
						ordered_positions = _sort_positions(SortCondition.POSITION, ordered_positions, dict)

					var packet = {"all_race_positions": ordered_positions}
					send_P2P_Packet("all", packet)"""

	else:
		time += delta / 10
		if time >= delta:
			time = 0
			# PING?

		if cam_on_stats:
			rect_position = lerp(rect_position, position_for_cam_on_stats, 0.2)
			if Global._vector_is_equal_approx_to_step(rect_position, position_for_cam_on_stats, 1):
				cam_on_stats = false

		if cam_on_lobby:
			rect_position = lerp(rect_position, position_for_cam_on_lobby, 0.2)
			if Global._vector_is_equal_approx_to_step(rect_position, position_for_cam_on_lobby, 1):
				cam_on_lobby = false

		if Input.is_action_just_pressed("send_message"):
			var focus_owner = chatInput.get_focus_owner()
			var conflicting_controls = [chatInput, lobbySetName]
			if not focus_owner in conflicting_controls:
				chatInput.grab_focus()
			elif chatInput.text == "":
				chatInputButton.grab_focus()
			else:
				_on_SendMessageButton_pressed()


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


func _sort_positions(condition_value: int, ordered_positions: Array, pos: Dictionary) -> Array:
	var condition = false

	# "ordered_positions" is a hopeful name - after this process is complete, they will be
	# ordered positions. Every position (ord_pos) is also seen as hopefully ordered by the end.

	for ord_pos in ordered_positions:
		if condition_value == SortCondition.LAP:
			condition = pos["lap"] > ord_pos["lap"]
		elif condition_value == SortCondition.POSITION:
			condition = pos["pos"] > ord_pos["pos"] and pos["lap"] == ord_pos["lap"]

		if condition:
			var index = ordered_positions.find(ord_pos)

			# Copy all the potentially affected positions (includes ord_pos)
			var ordered_positions_after_pos = ordered_positions.slice(index, len(ordered_positions) - 1)

			# Now overwrite in a destructive way
			ordered_positions[index] = pos

			# Then re-add the positions after in the same order
			for ord_pos_after in ordered_positions_after_pos:
				ordered_positions.erase(ord_pos_after)
				ordered_positions.append(ord_pos_after)

	return ordered_positions


func read_All_P2P_Packets(read_count: int = 0):
	if read_count >= Game.PACKET_READ_LIMIT:
		return
	if Steam.getAvailableP2PPacketSize(0) > 0:
		read_P2P_Packet()
		read_All_P2P_Packets(read_count + 1)


func get_lobby_data(key: String):
	# Implementation function to reduce other scripts' usage of Steam library
	return Steam.getLobbyData(Game.LOBBY_ID, key)


## Self-Made Functions


func create_Lobby() -> void:
	# Check no other lobbies are running
	if Game.LOBBY_ID == 0:
		Steam.createLobby(join_type, Game.MAX_MEMBERS)
		Game.PLAYER_DATA[Game.STEAM_ID] = {}
		Game.PLAYER_DATA[Game.STEAM_ID]["start_position"] = 0
	set_host_status(true)


func get_Lobby_Members() -> void:
	# Clear prev. lobby members list
	Game.LOBBY_MEMBERS.clear()

	# Get number of members in lobby
	var MEMBER_COUNT = Steam.getNumLobbyMembers(Game.LOBBY_ID)
	# Update player list count
	playerCount.set_text("Players: " + str(MEMBER_COUNT))

	# Get members data
	for MEMBER in range(0, MEMBER_COUNT):
		# Member's Steam ID
		var MEMBER_STEAM_ID = Steam.getLobbyMemberByIndex(Game.LOBBY_ID, MEMBER)
		# Member's Steam Name
		var MEMBER_STEAM_NAME = Steam.getFriendPersonaName(MEMBER_STEAM_ID)
		# Add members to list
		add_Player_List(MEMBER_STEAM_ID, MEMBER_STEAM_NAME)


func add_Player_List(steam_id, steam_name) -> void:
	# Add players to list
	Game.LOBBY_MEMBERS.append({"steam_id" : steam_id, "steam_name" : steam_name})
	# Ensure list is cleared
	for child in playerList.get_children():
		child.queue_free()

	var vehicle = " "

	# Populate player list
	for MEMBER in Game.LOBBY_MEMBERS:

		var text = ""

		# Establish player state
		if MEMBER["steam_id"] == Steam.getLobbyOwner(Game.LOBBY_ID):
			text += "(HOST) "

		text += MEMBER["steam_name"]

		if Game.PLAYER_DATA.has(MEMBER["steam_id"]):
			if Game.PLAYER_DATA[MEMBER["steam_id"]].has("ready"):
				var ready = Game.PLAYER_DATA[MEMBER["steam_id"]]["ready"]
				if ready:
					text += " [READY]"
		else:
			Game.PLAYER_DATA[MEMBER["steam_id"]] = {"steam_name": MEMBER["steam_name"]}

		var button = texButton.duplicate()
		button.name = str(MEMBER["steam_id"])
		button.get_node("Name").text = text
		button.show()

		#var popup = button.get_popup()
		#popup.add_separator(MEMBER["steam_name"])
		#if host and MEMBER["steam_name"] != Game.STEAM_NAME:
		#	popup.add_item("Make Host")
		#	popup.add_item("Kick")
		#	popup.add_item("Ban")
		#popup.add_item("View Steam Profile")
		#popup.connect("id_pressed", self, "_on_PlayerList_item_selected", [popup, button.name])

		playerList.add_child(button)


func send_Chat_Message(MESSAGE: String) -> void:
	# If the message is non-empty
	if MESSAGE.length() > 0:
		# Pass message to Steam
		var SENT: bool = Steam.sendLobbyChatMsg(Game.LOBBY_ID, MESSAGE)

		# Check message sent
		if not SENT:
			display_Message("ERROR: Chat message failed to send.")


func make_P2P_Handshake() -> void:
	# Sends a P2P handshake to the lobby
	send_P2P_Packet("all", {"message": "handshake"})


func read_P2P_Packet():
	var PACKET_SIZE: int = Steam.getAvailableP2PPacketSize(0)
	var CHANNEL: int = 0

	# If there is a packet
	if PACKET_SIZE > 0:
		var PACKET: Dictionary = Steam.readP2PPacket(PACKET_SIZE, CHANNEL)

		if PACKET.empty() or PACKET == null:
			print("WARNING: Read an empty packet with non-zero size!")

		# Get the remote user's ID
		var PACKET_SENDER: int = PACKET["steam_id_remote"]

		# Make the packet readable
		var PACKET_CODE: PoolByteArray = PACKET["data"]
		var READABLE: Dictionary = bytes2var(PACKET_CODE)

		# Print the packet to output
		print("Packet: " + str(READABLE))

		# Deal with packet data below

		## Lobby
		# a "message" packet.
		if READABLE.has("message"):
			# Handshake - we send all our data with the newcomer.
			if READABLE["message"] == "handshake":
				# If they are banned...
				if host and PACKET_SENDER in Game.BLACKLIST:
					send_P2P_Packet(str(PACKET_SENDER), {"banned": true})
				else:
					var their_data = Game.PLAYER_DATA[Game.STEAM_ID]
					if their_data.has("vehicle"):
						send_P2P_Packet(str(PACKET_SENDER), {"vehicle": their_data["vehicle"]})
					if their_data.has("ready"):
						send_P2P_Packet(str(PACKET_SENDER), {"ready": their_data["ready"]})

		if READABLE.has("set_host"):
			if Game.LOBBY_ID != 0:
				# We have been given host, or had host taken away from us (somehow).
				set_host_status(READABLE["set_host"])

		if READABLE.has("host_obtained"):
			if Game.LOBBY_ID != 0:
				# The new host has received our request to give them host; we
				# now need to provide them with any data the host needs.
				Game.PLAYER_DATA[PACKET_SENDER]["host"] = true
				if host:
					var HOST_DATA = {}
					HOST_DATA["join_type"] = join_type
					HOST_DATA["num_races"] = num_races
					send_P2P_Packet(str(PACKET_SENDER), {"host_data": HOST_DATA})

		if READABLE.has("host_data"):
			if Game.LOBBY_ID != 0:
				# We have received the data from the previous host, and must
				# interpret it and store it.
				var HOST_DATA = READABLE["host_data"]
				join_type = HOST_DATA["join_type"]
				num_races = HOST_DATA["num_races"]
				send_P2P_Packet(str(PACKET_SENDER), {"host_ack": true})

		if READABLE.has("host_ack"):
			if Game.LOBBY_ID != 0:
				# Our job as host is done, and we now retire host privileges.
				set_host_status(false)

		if READABLE.has("kicked"):
			if READABLE["kicked"]:
				if Game.LOBBY_ID != 0 and !host:
					_on_Back_pressed(LeaveReason.KICKED)

		if READABLE.has("banned"):
			if READABLE["banned"]:
				if Game.LOBBY_ID != 0 and !host:
					_on_Back_pressed(LeaveReason.BANNED)

		# a "vehicle" packet.
		if READABLE.has("vehicle"):
			Game.PLAYER_DATA[PACKET_SENDER]["vehicle"] = READABLE["vehicle"]

		if READABLE.has("map_vote"):
			Game.PLAYER_DATA[PACKET_SENDER]["map_vote"] = READABLE["map_vote"]

		# a "ready" packet. Can assume a steam_id will be provided
		# Note: It is up to the final readier to send an "all_ready" packet.
		if READABLE.has("ready"):
			Game.PLAYER_DATA[PACKET_SENDER]["ready"] = READABLE["ready"]
			get_Lobby_Members()

		# a "pre_config_complete" packet. Can assume a steam_id will be provided
		# The players pre config one after the other to ensure we can control data in a non-chaotic way.
		# Note: It is up to the final readier to send an "all_pre_configs_complete" message packet.
		if READABLE.has("pre_config_complete"):
			# If we haven't already preloaded, we can preload.
			var gets_to_pre_load = false
			if !Game.PLAYER_DATA[Game.STEAM_ID].has("pre_config_complete"):
				gets_to_pre_load = true
			elif !Game.PLAYER_DATA[Game.STEAM_ID]["pre_config_complete"]:
				gets_to_pre_load = true

			if gets_to_pre_load:
				Game.PLAYER_DATA[PACKET_SENDER]["pre_config_complete"] = true

				if READABLE["pre_config_complete"].has("map"):
					# Get the randomly selected map from the person who just readied up
					selected_map = READABLE["pre_config_complete"]["map"]

				# Our turn to handle preconfig
				_on_All_Ready()

				# Check if all preconfigs are complete, and if so, send an "all_pre_configs_complete" packet.
				var all_pre_configs_complete = true
				var ids = Game.PLAYER_DATA.keys()

				for player_id in ids:
					if Game.PLAYER_DATA[player_id].has("pre_config_complete"):
						if Game.PLAYER_DATA[player_id]["pre_config_complete"]:
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
					_on_All_Pre_Configs_Complete()

		if READABLE.has("all_pre_configs_complete"):
			if READABLE["all_pre_configs_complete"]:
				_on_All_Pre_Configs_Complete()

		# a "bot_vehicle" packet. Will be sent by the host to all clients. Is a Dictionary object.
		if READABLE.has("bot_vehicle"):
			var bot_vehicle: Dictionary = READABLE["bot_vehicle"]
			if !bot_vehicle["name"] in Game.BOT_DATA:
				Game.BOT_DATA[bot_vehicle["name"]] = {"vehicle": bot_vehicle["vehicle"]}
			else:
				Game.BOT_DATA[bot_vehicle["name"]]["vehicle"] = bot_vehicle["vehicle"]

			if Game.BOT_DATA.size() == Game.MAX_MEMBERS - Game.PLAYER_DATA.size():
				start_Bot_Config()

		## In-Game
		# a "position" packet.
		if READABLE.has("position"):
			if PACKET_SENDER != Game.STEAM_ID:
				# We don't want to update our correct position with the network's estimated position
				var player = get_node("/root/Scene/Players/" + str(PACKET_SENDER))

				if !lerps.has(PACKET_SENDER):
					lerps[PACKET_SENDER] = {}
				lerps[PACKET_SENDER]["position"] = READABLE["position"]

		# a "rotation" packet.
		if READABLE.has("rotation"):
			if PACKET_SENDER != Game.STEAM_ID:
				# We don't want to update our correct rotation with the network's estimated rotation
				var player = get_node("/root/Scene/Players/" + str(PACKET_SENDER))

				if !lerps.has(PACKET_SENDER):
					lerps[PACKET_SENDER] = {}
				lerps[PACKET_SENDER]["rotation"] = READABLE["rotation"]

		"""if READABLE.has("all_race_positions"):
			if PACKET_SENDER != Game.STEAM_ID:
				for player_id in READABLE["all_race_positions"]:
					Game.PLAYER_DATA[player_id]["race_pos"] = READABLE["all_race_positions"][player_id]"""


func send_P2P_Packet(target: String, packet_data: Dictionary) -> void:
	# Assign SendType and channel
	var send_type: int = SendType.Reliable
	var CHANNEL: int = 0

	# Create a data array to send the data through
	var DATA: PoolByteArray
	DATA.append_array(var2bytes(packet_data))

	# If sending a packet to everyone
	if target == "all":
		# If there is more than one user, send packets
		if Game.LOBBY_MEMBERS.size() > 1:
			# Loop through all members that aren't you
			for MEMBER in Game.LOBBY_MEMBERS:
				if MEMBER['steam_id'] != Game.STEAM_ID:
					Steam.sendP2PPacket(MEMBER['steam_id'], DATA, send_type, CHANNEL)

	# Else sending it to someone specific
	else:
		Steam.sendP2PPacket(int(target), DATA, send_type, CHANNEL)


func set_host_status(set_host: bool) -> void:
	host = set_host

	if host:
		lobbySettings.show()
		send_P2P_Packet("all", {"host_obtained": true})
	else:
		lobbySettings.hide()


func leave_Lobby() -> void:
	# If we are in a lobby, leave it.
	if Game.LOBBY_ID != 0:
		display_Message("Leaving lobby...")

		# Reset host status first, if we are host
		if len(Game.PLAYER_DATA) > 1 and host:
			# If there is someone else to give host to, give it to the first
			# person who joined (excluding us).
			send_P2P_Packet(Game.PLAYER_DATA[0], {"set_host": true})

		# Send leave request
		Steam.leaveLobby(Game.LOBBY_ID)

		# Wipe Lobby ID (to show we aren't in a lobby anymore)
		Game.LOBBY_ID = 0

		playerCount.text = "Players: 0"

		# Empty the playerlist
		for child in playerList.get_children():
			child.queue_free()

		# Close any possible sessions with other users
		for MEMBERS in Game.LOBBY_MEMBERS:
			Steam.closeP2PSessionWithUser(MEMBERS["steam_id"])

		# Clear lobby list
		Game.LOBBY_MEMBERS.clear()


func display_Message(message) -> void:
	# Adds a new message to the chat box.
	chatOutput.add_text("\n" + str(message))


func fix_vehicle_sprite() -> void:
	var sprite = $Vehicle/VehicleSprite
	var height = sprite.texture.get_height()
	var width = sprite.texture.get_width()
	sprite.position = $Vehicle.get_rect().size / 2

	if height > $Vehicle.get_rect().size.x:
		sprite.scale.y = $Vehicle.get_rect().size.x / height
	if width > $Vehicle.get_rect().size.y:
		sprite.scale.x = $Vehicle.get_rect().size.y / width


func start_Pre_Config() -> void:
	if !local_pre_config_done:
		var map = load("res://Scenes/Maps/" + selected_map + ".tscn").instance()
		my_player = Global._setup_scene(Global.GameMode.MULTI, map, 12)

		local_pre_config_done = true

		if final_readier:
			send_P2P_Packet("all", {"pre_config_complete": {"map": selected_map}})
		else:
			send_P2P_Packet("all", {"pre_config_complete": true})


func start_Bot_Config() -> void:
	for i in range(Game.BOT_DATA.size()):
		var vehicle = Game.BOT_DATA["BOT" + str(i)]["vehicle"]

		var bot = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()
		bot.set_name("BOT" + str(i))
		var bots = get_node("/root/Scene/Bots")
		bots.add_child(bot)

		var cam = preload("res://Scenes/Cam.tscn").instance()
		cam.set_name("BOTCAM_" + str(i))
		bot.add_child(cam)


func start_Game() -> void:
	# ! Need to set this to false whenever it ends.
	Game.GAME_STARTED = true


## Steam Callbacks


func generate_random_code():
	randomize()
	var lobby_name = ""
	var characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	for i in range(5):
		lobby_name += characters[randi() % len(characters)]


# Lobby (No charselect popup)
func _on_Lobby_Created(connect, lobbyID):
	if connect == 1:
		# Set Lobby ID
		Game.LOBBY_ID = lobbyID

		#!!!generate_random_code()

		# Equivalent of printing into the chatbox
		display_Message("Created lobby: " + lobby_name)

		# Make it joinable (this should be done by default anyway)
		Steam.setLobbyJoinable(lobby_id, true)

		# Set Lobby Data - this is custom data, I need to do this manually.
		Steam.setLobbyData(lobbyID, "name", lobby_name)
		Steam.setLobbyData(lobbyID, "type", JoinType.keys()[join_type])

		Steam.setLobbyMemberLimit(lobbyID, Game.MAX_MEMBERS)

		var RELAY = Steam.allowP2PPacketRelay(true)
		print("Allowing Steam to be relay backup: " + str(RELAY))


func _on_Lobby_Joined(lobbyID, perms, locked, response) -> void:
	# Success
	if response == 1:
		# Set lobby ID
		Game.LOBBY_ID = lobbyID

		# Get lobby name
		var name = Steam.getLobbyData(lobbyID, "name")

		# Get lobby members
		get_Lobby_Members()

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
	if chatState == 1:
		display_Message(str(CHANGER) + " has joined the lobby.")
	elif chatState == 2:
		display_Message(str(CHANGER) + " has left the lobby.")
	elif chatState == 4:
		display_Message(str(CHANGER) + " has disconnected from the lobby.")
	elif chatState == 8:
		display_Message(str(CHANGER) + " has been kicked from the lobby.")
	elif chatState == 16:
		display_Message(str(CHANGER) + " has been banned the lobby.")
	else:
		display_Message(str(CHANGER) + " did... something.")

	# Update lobby
	get_Lobby_Members()


func _on_Lobby_Message(result, user, message, type) -> void:
	# Display the sender and their message
	var SENDER = Steam.getFriendPersonaName(user)
	display_Message(str(SENDER) + ": " + str(message))


func _on_Lobby_Invite():
	pass


func _on_Persona_Change(steam_id: int, flag: int) -> void:
	# A user has had an info change; update the lobby list
	display_Message("Persona change has occurred, lobby list will now refresh.")
	# Update the lobby list
	get_Lobby_Members()


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


## Other "on" functions


func _on_All_Ready():
	# Initially, only run by the last player to ready up. Then the others are notified in order and they each call this.
	get_tree().set_pause(true)

	if final_readier:
		var map_votes = []
		for player_id in Game.PLAYER_DATA:
			map_votes.append(Game.PLAYER_DATA[player_id]["map_vote"])
		selected_map = Global.get_random_arrayitem(map_votes)
	start_Pre_Config()

	var ids = Game.PLAYER_DATA.keys()
	var num_players = len(ids)
	var num_bots = 0 #Game.MAX_MEMBERS - num_players


	if host:
		pass
		#for i in range(num_bots):
		#	var name = "BOT" + str(i)
		#	var vehicle = Global.get_random_scene(Global.SceneType.VEHICLE)
		#	if !(name in Game.BOT_DATA):
		#		Game.BOT_DATA[name] = {"vehicle": vehicle}
		#	else:
		#		Game.BOT_DATA[name]["vehicle"] = vehicle
		#	send_P2P_Packet("all", {"bot_vehicle": {"name": "BOT" + str(i), "vehicle": vehicle}})
		#start_Bot_Config()
	Game.PLAYER_DATA[Game.STEAM_ID]["pre_config_complete"] = true
	get_tree().set_pause(false)


func _on_All_Pre_Configs_Complete():
	get_tree().set_pause(true)
	start_Game()
	get_tree().set_pause(false)


## Button Signal Functions


func _on_LobbyNameEdit_text_entered(new_text):
	Steam.setLobbyData(Game.LOBBY_ID, "name", new_text)
	display_Message("Lobby name changed to: " + new_text)


func _on_Vehicle_Selected(vehicle: String):
	if Game.LOBBY_ID != 0:
		send_P2P_Packet("all", {"vehicle": vehicle})
		Game.PLAYER_DATA[Game.STEAM_ID]["vehicle"] = vehicle

		var vehicle_obj = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()
		$Vehicle/VehicleSprite.texture = vehicle_obj.get_node("VehicleSprite").get_texture()
		fix_vehicle_sprite()
		$Vehicle/VehicleName.text = vehicle


func _on_VehicleLeftButton_pressed():
	var current_index = Global.VEHICLES.find($Vehicle/VehicleName.text)
	var next_vehicle = Global.VEHICLES[current_index - 1]
	_on_Vehicle_Selected(next_vehicle)


func _on_VehicleRightButton_pressed():
	var current_index = Global.VEHICLES.find($Vehicle/VehicleName.text)
	var next_vehicle
	if current_index + 1 == len(Global.VEHICLES):
		next_vehicle = Global.VEHICLES[0]
	else:
		next_vehicle = Global.VEHICLES[current_index + 1]

	_on_Vehicle_Selected(next_vehicle)


func _on_Map_Selected(map_name: String):
	if Game.LOBBY_ID != 0:
		send_P2P_Packet("all", {"map_vote": map_name})
		Game.PLAYER_DATA[Game.STEAM_ID]["map_vote"] = map_name
		_on_Start_pressed()


func _on_Start_pressed():
	if Game.LOBBY_ID != 0:
		var all_ready = true

		# Random selections if selections haven't been made
		if !Game.PLAYER_DATA[Game.STEAM_ID].has("vehicle"):
			var vehicle = Global.get_random_scene(Global.SceneType.VEHICLE)
			Game.PLAYER_DATA[Game.STEAM_ID]["vehicle"] = vehicle
			send_P2P_Packet("all", {"vehicle": vehicle})
		if !Game.PLAYER_DATA[Game.STEAM_ID].has("map_vote"):
			var map = Global.get_random_scene(Global.SceneType.MAP)
			Game.PLAYER_DATA[Game.STEAM_ID]["map_vote"] = map
			send_P2P_Packet("all", {"map_vote": map})

		# Toggle readiness if present, or activate it if not
		if Game.PLAYER_DATA[Game.STEAM_ID].has("ready"):
			var ready = Game.PLAYER_DATA[Game.STEAM_ID]["ready"]
			send_P2P_Packet("all", {"ready": !ready})
			Game.PLAYER_DATA[Game.STEAM_ID]["ready"] = !ready
			# Refresh the lobby as your readiness has changed.
			get_Lobby_Members()
		else:
			send_P2P_Packet("all", {"ready": true})
			Game.PLAYER_DATA[Game.STEAM_ID]["ready"] = true
			# Refresh the lobby as your readiness has changed.
			get_Lobby_Members()

		# Check if last to ready up - this means I am the "all_ready" starter
		for player_id in Game.PLAYER_DATA:
			if Game.PLAYER_DATA[player_id].has("ready"):
				if Game.PLAYER_DATA[player_id].has("vehicle"):
					if Game.PLAYER_DATA[player_id]["ready"]:
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
			_on_All_Ready()


func _on_Back_pressed(reason: int = LeaveReason.NONE):
	var scene = load("res://Scenes/MenuMulti.tscn").instance()
	get_node("/root").add_child(scene)
	match reason:
		LeaveReason.NONE:
			pass
		LeaveReason.KICKED:
			var accept_dialog = scene.get_node("AcceptDialog")
			accept_dialog.dialog_text = "You have been kicked from " + Steam.getLobbyData(Game.LOBBY_ID, "name")
			accept_dialog.popup()
		LeaveReason.BANNED:
			var accept_dialog = scene.get_node("AcceptDialog")
			accept_dialog.dialog_text = "You have been banned from " + Steam.getLobbyData(Game.LOBBY_ID, "name")
			accept_dialog.popup()
	leave_Lobby()
	self.queue_free()


func _on_SendMessageButton_pressed() -> void:
	var message = chatInput.text
	chatInput.text = ""
	send_Chat_Message(message)


func _on_PlayerList_item_selected(id: int, popup, player_id_as_string: String) -> void:
	match popup.get_item_text(id):
		"Make Host":
			# Note that we will remain host until the new host acknowledges it with a
			# "host_obtained" packet.
			send_P2P_Packet(player_id_as_string, {"set_host": true})
		"Kick":
			send_P2P_Packet(player_id_as_string, {"kicked": true})
		"Ban":
			Game.BLACKLIST.append(int(player_id_as_string))
			send_P2P_Packet(player_id_as_string, {"banned": true})
		"View Steam Profile":
			Steam.activateGameOverlayToUser("steamid", int(player_id_as_string))


func _on_StatsButton_pressed():
	if !cam_on_stats and !cam_on_lobby:
		cam_on_stats = true


func _on_LobbyButton_pressed():
	if !cam_on_lobby and !cam_on_stats:
		cam_on_lobby = true


func _on_LobbySettingsButton_pressed():
	lobbySettingsPopup.popup()
	lobbySettings.disabled = true


func _on_LobbySettingsCloseButton_pressed():
	print("HI")
	lobbySettingsPopup.hide()
	lobbySettings.disabled = false
