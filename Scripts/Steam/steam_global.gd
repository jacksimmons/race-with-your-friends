extends Node

# Network Variables
var PACKET_READ_LIMIT = 250

# Steam Variables
var OWNED := false
var ONLINE := false
var STEAM_ID := 0
var STEAM_NAME := ""

# Lobby Variables
var DATA
var LOBBY_ID := 0
var LOBBY_MEMBERS := []
var LOBBY_INVITE_ARG
var MAX_MEMBERS := 12
var MAX_LOBBY_RESULTS := 50

# Game Variables
var PLAYER_DATA := {}
var BOT_DATA := {}
var NUM_CHECKPOINTS := 0
var GAME_STARTED := false
var BLACKLIST := []


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


func _process(delta):
	Steam.run_callbacks()


# Command Line Checking


func check_Command_Line():
	var ARGUMENTS = OS.get_cmdline_args()

	# Check if detected arguments
	if ARGUMENTS.size() > 0:
		for arg in ARGUMENTS:
			# Invite arg passed
			if Game.LOBBY_INVITE_ARG:
				join_Lobby(int(arg))

			# Steam connection arg
			if arg == "+connect_lobby":
				Game.LOBBY_INVITE_ARG = true


# Global lobby functions

func join_Lobby(lobbyID) -> void:
	# Gets value of the "name" key with provided lobbyID
	var name = Steam.getLobbyData(lobbyID, "name")

	# Clear prev. lobby members lists
	LOBBY_MEMBERS.clear()

	# Load lobby scene
	var loaded_lobby = preload("res://Scenes/LobbyMulti.tscn").instance()
	get_node("/root").add_child(loaded_lobby)

	# Steam join request
	Steam.joinLobby(lobbyID)


# Global Steam callbacks

func _on_Lobby_Join_Requested(lobbyID, friendID) -> void:
	# Callback occurs when attempting to join via Steam overlay

	# Get lobby owner's name
	var OWNER_NAME = Steam.getFriendPersonaName(friendID)

	# Join the lobby
	join_Lobby(lobbyID)
