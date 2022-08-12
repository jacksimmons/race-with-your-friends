extends MenuButton

onready var editor = $"/root/Editor"

# Unsaved Progress Dialogs call their parents.
var unsaved_progress_dialog
onready var no_scene_dialog = $"/root/Editor/Canvas/UI/Tabs/File/New/NoSceneDialog"
onready var no_scene_to_playtest_dialog = $"/root/Editor/Canvas/UI/Tabs/Test/Playtest/NoSceneDialog"
onready var no_map_dialog = $"/root/Editor/Canvas/UI/Tabs/Test/Playtest/NoMapDialog"

var selected_id: int = -1
var file_dialog: FileDialog

# Called when the node enters the scene tree for the first time.
func _ready():
	var new_popup = get_popup()
	
	if name == "New":
		unsaved_progress_dialog = $UnsavedProgressDialog
		new_popup.add_item("Map")
		new_popup.add_item("Object")
		new_popup.add_item("Vehicle")
	
	elif name == "Open":
		unsaved_progress_dialog = $UnsavedProgressDialog
		new_popup.add_item("From file")
		file_dialog = $FileDialog
		file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		file_dialog.filters = PoolStringArray(["*.tscn ; Godot Scenes"])

	elif name == "Save":
		new_popup.add_item("Save As...")
			
		file_dialog = $FileDialog
		file_dialog.access = FileDialog.ACCESS_RESOURCES
		file_dialog.filters = PoolStringArray(["*.tscn ; Godot Scenes"])

	elif name == "Playtest":
		for vehicle in Global.VEHICLE_BASE_STATS.keys():
			new_popup.add_item(vehicle)

	new_popup.connect("id_pressed", self, "_on_item_pressed")
	add_color_override("font_color_hover", Color.darkgreen)


func _handle_new():
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


func _on_item_pressed(id):
	# Global for other functions
	selected_id = id
	
	if name == "New":
		if editor.progress:
			unsaved_progress_dialog.popup()
		else:
			_handle_new()
	
	elif name == "Open":
		if editor.progress:
			unsaved_progress_dialog.popup()
		else:
			file_dialog.popup()
	
	elif name == "Save":
		if editor.project_root.get_child_count() == 0:
			no_scene_dialog.popup()
		else:
			if selected_id == 0:
				_save_as()
			elif selected_id == 1:
				_save(editor.current_file)
		
	elif name == "Playtest":
		if editor.project_root.get_child_count() == 0:
			no_scene_to_playtest_dialog.popup()
		else:
			var there_is_a_map = false
			if editor.project_root.name == "Map":
				there_is_a_map = true
			
			if there_is_a_map:
				var vehicle_name = get_popup().get_item_text(selected_id)
				var vehicle = load("res://Scenes/Vehicles/" + vehicle_name + ".tscn").instance()
				var scene = preload("res://Scenes/Scene.tscn").instance()
				var map = editor.project_root.get_node("Map")
				var cam = preload("res://Scenes/Cam.tscn").instance()
				
				vehicle.my_data = {"vehicle": vehicle_name}
				
				vehicle.add_child(cam)
				scene.get_node("Map").add_child(map)
				scene.get_node("Game").add_child(vehicle)
				
				get_node("/root").add_child(scene)
				
			else:
				no_map_dialog.popup()


func _on_UnsavedProgressDialog_confirmed():
	print(name + " " + str(selected_id))
	if name == "New":
		_handle_new()
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
