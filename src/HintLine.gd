extends Line2D

func show_hint(path: PathData) -> void:
	points = []
	for point in path.get_line_path():
		add_point(point)

func remove_hint():
	points = []


func _on_Tiles_pair_cleared(_pair) -> void:
	remove_hint()
