extends Node

var start_points: Array


func _ready():
	if $StartPoints.get_child_count() > 0:
		for start_point in $StartPoints.get_children():
			var total_position = Vector2()
			for point_corner in start_point.get_children():
				total_position += point_corner.position
			var avg_position = total_position / start_point.get_child_count()
			start_points.append(avg_position)
