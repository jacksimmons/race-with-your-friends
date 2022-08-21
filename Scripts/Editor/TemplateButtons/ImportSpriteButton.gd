extends Button

onready var editor = $"/root/Editor"
onready var file_dialog = $FileDialog

var sprite_node: Sprite


func _ready():
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.current_dir = "res://Mods"
	file_dialog.resizable = true
	file_dialog.mode = FileDialog.MODE_OPEN_FILE
	file_dialog.filters = PoolStringArray(["*.png ; PNG Images"])


func _on_Button_pressed():
	file_dialog.popup()


func _on_FileDialog_file_selected(path: String):
	var file = File.new()
	file.open(path, File.READ)
	var buffer = file.get_buffer(file.get_len())

	var img = Image.new()
	img.load_png_from_buffer(buffer)

	var img_tex = ImageTexture.new()
	img_tex.create_from_image(img)

	sprite_node.set_texture(img_tex)

	editor.refresh_nodes()
