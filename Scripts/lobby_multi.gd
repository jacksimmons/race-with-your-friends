extends Control

# Onreadies
onready var lobby_set_name = $Settings/Popup/LobbyNameEdit
onready var lobby_settings = $Settings/LobbySettingsButton
onready var lobby_settings_popup = $Settings/Popup

onready var chat_input = $Chat/TextEdit
onready var chat_output = $Chat/MessageList

onready var player_count = $Players/NoOfPlayers
onready var player_list = $Players/PlayerList

onready var tex_button = $Players/TextureButton

onready var chat_input_button = $Chat/SendMessageButton

onready var cam = $Camera2D

# Signals
signal vehicle_selected
signal map_selected
signal player_ready

# Lobby

var cam_on_stats: bool = false
var cam_on_lobby: bool = false
var position_for_cam_on_stats := Vector2(-1920, 0)
var position_for_cam_on_lobby := Vector2(0, 0)

var message_input_shown: bool = false

var all_ready: bool = false
var all_pre_configs_complete: bool = false
var local_pre_config_done: bool = false

# Game
var time: float = 0
var my_player = null
var position_last_update: Vector2 = Vector2.ZERO
var rotation_last_update: int = 0
var race_position_last_update: Dictionary = {}


func _ready():
	#Place vehicle sprite in the correct position
	fix_vehicle_sprite()

	Server.connect("host_status_update", self, "_on_host_status_update")
	Server.connect("vehicle_update", self, "_on_vehicle_update")
	Server.connect("player_list_update", self, "_on_player_list_update")
	Server.connect("lobby_message", self, "_on_lobby_message")

	Server.lobby_screen_entered()


func _process(delta):
	if cam_on_stats:
		rect_position = lerp(rect_position, position_for_cam_on_stats, 0.2)
		if Global._vector_is_equal_approx_to_step(rect_position, position_for_cam_on_stats, 1):
			cam_on_stats = false

	if cam_on_lobby:
		rect_position = lerp(rect_position, position_for_cam_on_lobby, 0.2)
		if Global._vector_is_equal_approx_to_step(rect_position, position_for_cam_on_lobby, 1):
			cam_on_lobby = false

	if Input.is_action_just_pressed("send_message"):
		var focus_owner = chat_input.get_focus_owner()
		var conflicting_controls = [chat_input, lobby_set_name]
		if not focus_owner in conflicting_controls:
			chat_input.grab_focus()
		elif chat_input.text == "":
			chat_input_button.grab_focus()
		else:
			_on_SendMessageButton_pressed()


func fix_vehicle_sprite() -> void:
	var sprite = $Vehicle/VehicleSprite
	var height = sprite.texture.get_height()
	var width = sprite.texture.get_width()
	sprite.position = $Vehicle.get_rect().size / 2

	if height > $Vehicle.get_rect().size.x:
		sprite.scale.y = $Vehicle.get_rect().size.x / height
	if width > $Vehicle.get_rect().size.y:
		sprite.scale.x = $Vehicle.get_rect().size.y / width


func display_message(message) -> void:
	# Adds a new message to the chat box.
	chat_output.add_text("\n" + str(message))


func start_Bot_Config() -> void:
	for i in range(Server.bot_data.size()):
		var vehicle = Server.bot_data["BOT" + str(i)]["vehicle"]

		var bot = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()
		bot.set_name("BOT" + str(i))
		var bots = get_node("/root/Scene/Bots")
		bots.add_child(bot)

		var cam = preload("res://Scenes/Cam.tscn").instance()
		cam.set_name("BOTCAM_" + str(i))
		bot.add_child(cam)


## Steam Callbacks

# Lobby (No charselect popup)


## Button Signal Functions


func _on_LobbyNameEdit_text_entered(new_text):
	Steam.setLobbyData(Server.lobby_id, "name", new_text)
	display_message("Lobby name changed to: " + new_text)


func _on_VehicleLeftButton_pressed():
	var current_index = Global.VEHICLES.find($Vehicle/VehicleName.text)
	var next_vehicle = Global.VEHICLES[current_index - 1]
	emit_signal("vehicle_selected", next_vehicle)


func _on_VehicleRightButton_pressed():
	var current_index = Global.VEHICLES.find($Vehicle/VehicleName.text)
	var next_vehicle
	if current_index + 1 == len(Global.VEHICLES):
		next_vehicle = Global.VEHICLES[0]
	else:
		next_vehicle = Global.VEHICLES[current_index + 1]

	emit_signal("vehicle_selected", next_vehicle)


func _on_Map_Selected(map_name: String):
	emit_signal("map_selected", map_name)
	_on_Start_pressed()
	hide()


func _on_host_status_update(host: bool) -> void:
	if host:
		lobby_settings.show()
	else:
		lobby_settings.hide()


func _on_vehicle_update(vehicle: String) -> void:
	var vehicle_obj = load("res://Scenes/Vehicles/" + vehicle + ".tscn").instance()
	$Vehicle/VehicleSprite.texture = vehicle_obj.get_node("VehicleSprite").get_texture()
	fix_vehicle_sprite()
	$Vehicle/VehicleName.text = vehicle


func _on_player_list_update(lobby_members: Array) -> void:
	# Set player count
	player_count.set_text("Players: " + str(len(lobby_members)))

	# Ensure list is cleared
	for child in player_list.get_children():
		child.queue_free()

	# Populate player list
	for member in lobby_members:

		var text = ""

		# Establish player state
		if member["steam_id"] == Steam.getLobbyOwner(Server.lobby_id):
			text += "(HOST) "

		text += member["steam_name"]

		if Server.player_data.has(member["steam_id"]):
			if Server.player_data[member["steam_id"]].has("ready"):
				var ready = Server.player_data[member["steam_id"]]["ready"]
				if ready:
					text += " [READY]"
		else:
			Server.player_data[member["steam_id"]] = {"steam_name": member["steam_name"]}

		var button = tex_button.duplicate()
		button.name = str(member["steam_id"])
		button.get_node("Name").text = text
		button.show()

		#var popup = button.get_popup()
		#popup.add_separator(member["steam_name"])
		#if host and member["steam_name"] != STEAM_NAME:
		#	popup.add_item("Make Host")
		#	popup.add_item("Kick")
		#	popup.add_item("Ban")
		#popup.add_item("View Steam Profile")
		#popup.connect("id_pressed", self, "_on_PlayerList_item_selected", [popup, button.name])

		player_list.add_child(button)


func _on_lobby_message(result, user, message, type) -> void:
	# Display the sender and their message
	var SENDER = Steam.getFriendPersonaName(user)
	display_message(str(SENDER) + ": " + str(message))


func _on_Start_pressed():
	emit_signal("player_ready")


func _on_Back_pressed():
	var scene = load("res://Scenes/MenuMulti.tscn").instance()
	get_node("/root").add_child(scene)
	Server.leave_Lobby()
	self.queue_free()


func _on_SendMessageButton_pressed() -> void:
	var message = chat_input.text
	chat_input.text = ""
	Server.send_Chat_Message(message)


func _on_PlayerList_item_selected(id: int, popup, player_id_as_string: String) -> void:
	match popup.get_item_text(id):
		"Make Host":
			# Note that we will remain host until the new host acknowledges it with a
			# "host_obtained" packet.
			Server.send_P2P_Packet(player_id_as_string, {"set_host": true})
		"Kick":
			Server.send_P2P_Packet(player_id_as_string, {"kicked": true})
		"Ban":
			Server.blacklist.append(int(player_id_as_string))
			Server.send_P2P_Packet(player_id_as_string, {"banned": true})
		"View Steam Profile":
			Steam.activateGameOverlayToUser("steamid", int(player_id_as_string))


func _on_StatsButton_pressed():
	if !cam_on_stats and !cam_on_lobby:
		cam_on_stats = true


func _on_LobbyButton_pressed():
	if !cam_on_lobby and !cam_on_stats:
		cam_on_lobby = true


func _on_LobbySettingsButton_pressed():
	lobby_settings_popup.popup()
	lobby_settings.disabled = true


func _on_LobbySettingsCloseButton_pressed():
	lobby_settings_popup.hide()
	lobby_settings.disabled = false
