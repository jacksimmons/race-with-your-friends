extends Label

var delta_count = 0
var start_time = -1


func _process(delta):
	delta_count += 1
	text = Global._format_time(delta_count * delta, Global.TimeFormat.HHMMSSMSMS)
