extends GridContainer


var vehicle_buttons = []


func _ready():
	for child in get_children():
		vehicle_buttons.append(child)


func _on_Button_Pressed(vehicle):
	Server.PLAYER_DATA[Server.STEAM_ID]["vehicle"] = vehicle
