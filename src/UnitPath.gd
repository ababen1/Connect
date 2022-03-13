class_name UnitPath
extends TileMap

signal path_drawn
signal path_deleted

onready var line = $Line2D

func draw(current_path: PoolVector2Array) -> void:
	for point in current_path:
		set_cellv(point, 1)
	update_bitmask_region()
	emit_signal("path_drawn")

func draw_line_path(path: PoolVector2Array, color: = Color.blanchedalmond, width: = 2.0) -> void:
	for cell in path:
		line.add_point(map_to_world(cell) + cell_size / 2)
	line.default_color = color

func delete_line_path() -> void:
	line.points = []

func stop() -> void:
	clear()
	delete_line_path()
	emit_signal("path_deleted")
