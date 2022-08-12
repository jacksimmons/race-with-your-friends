extends MenuButton

onready var editor = $"/root/Editor"
onready var no_scene_dialog = $NoSceneDialog

var selected_id: int

# Called when the node enters the scene tree for the first time.
func _ready():
	selected_id = -1
	var new_popup = get_popup()
	
	for vehicle in Global.VEHICLE_BASE_STATS.keys():
		new_popup.add_item(vehicle)

	new_popup.connect("id_pressed", self, "_on_item_pressed")
	add_color_override("font_color_hover", Color.darkgreen)


func _on_item_pressed(id):
	selected_id = id
	
	if editor.progress and editor.project_root.get_child_count() == 0:
		no_scene_dialog.popup()
	
	var vehicle = load("res://Scenes/Vehicles/" + get_popup().get_item_text(id))


func _on_UnsavedProgressDialog_confirmed():
	if selected_id != -1:
		if name == "New":
			if selected_id == 0:
				# Map
				var map = preload("res://Scenes/Templates/DefaultMapScene.tscn").instance()
				editor.replace_project_root(map)
				editor.refresh_nodes()
			elif selected_id == 1:
				# Object
				var obj = preload("res://Scenes/Templates/DefaultObjectScene.tscn").instance()
				editor.replace_project_root(obj)
				editor.refresh_nodes()
			elif selected_id == 2:
				# Vehicle
				var vehicle = preload("res://Scenes/Templates/DefaultVehicleScene.tscn").instance()
				editor.replace_project_root(vehicle)
				editor.refresh_nodes()
		elif name == "Open":
			if selected_id == 0:
				# Open from file
				file_dialog.popup()


func _save(path: String):
	var packed_scene = PackedScene.new()
	packed_scene.pack(editor.project_root)
	ResourceSaver.save(path, packed_scene)
	editor.set_current_file(path)	


func _save_as():
	# Instead of directly saving, wait for FileDialog
	# to give us a file to save to.
	file_dialog.popup()


func _on_UnsavedProgressDialog_cancelled():
	selected_id = -1


func _on_FileDialog_file_selected(path):
	if name == "Open":
		editor.replace_project_root(load(path).instance())
		editor.refresh_nodes()
	elif name == "Save":
		_save(path)
