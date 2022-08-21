extends ConfirmationDialog

# When instancing this scene, set the caller to the Node which calls it.


func _ready():
	popup_centered()
	hide()

	# Okay pressed
	connect("confirmed", get_parent(), "_on_UnsavedProgressDialog_confirmed")
	# Cancel pressed
	get_cancel().connect("pressed", get_parent(), "_on_UnsavedProgressDialog_cancelled")
	# Closed without cancel
	connect("modal_closed", get_parent(), "_on_UnsavedProgressDialog_cancelled")
