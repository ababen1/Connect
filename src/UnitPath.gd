## Draws the unit's movement path using an autotile.
class_name UnitPath
extends TileMap

signal path_drawn
signal path_deleted

## Finds and draws the path between `cell_start` and `cell_end`
func draw(current_path: PoolVector2Array) -> void:
	clear()
	for point in current_path:
		set_cellv(point, 1)
	update_bitmask_region()
	emit_signal("path_drawn")


## Stops drawing, clearing the drawn path and the `_pathfinder`.
func stop() -> void:
	clear()
	emit_signal("path_deleted")
