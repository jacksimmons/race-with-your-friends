extends GridContainer


var vehicle_buttons = []


func _ready():
	for child in get_children():
		vehicle_buttons.append(child)


func _on_Button_Pressed(vehicle):
	SteamGlobals.SELECTED_VEHICLE = vehicle
	
	#if Server.active:
	#	Server._upload_vehicle()
	#else:
	#	Server._pre_config()
	#self.queue_free()
