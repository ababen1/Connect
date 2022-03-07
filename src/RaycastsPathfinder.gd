extends Node2D
class_name RaycastsPathfinder

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var grid: ConnectGameTilemap

func _ready() -> void:
	self.grid = get_parent()

func create_raycast(cell: Vector2) -> PathRaycast:
	var raycast = PathRaycast.new()
	add_child(raycast)
	raycast.add_exception(grid.get_area2D_at(cell))
	raycast.global_position = grid.to_global(
		grid.map_to_world(cell)) + grid.cell_size / 2
	return raycast

func find_shortest_path(start: Vector2, end: Vector2) -> PoolVector2Array:
	var raycast_start: = create_raycast(start)
	var raycast_end: = create_raycast(end)
	raycast_start.add_exception(grid.get_area2D_at(end))
	raycast_end.add_exception(grid.get_area2D_at(start))
	var distance_between_tiles: = raycast_start.global_position.distance_to(
		raycast_end.global_position)
	
	# Try connecting them directly
	if raycast_start.global_position.direction_to(
		raycast_end.global_position) in DIRECTIONS:
			raycast_start.cast_to = raycast_start.global_position.direction_to(
				raycast_end.global_position) * distance_between_tiles
			raycast_start.force_raycast_update()
			if not raycast_start.is_colliding():
				var connecting_line: = Line2D.new()
				connecting_line.points = [
					raycast_start.global_position,
					raycast_end.global_position]
				return raycasts_to_path(raycast_start, raycast_end, connecting_line)
	else:
		pass
	return PoolVector2Array([])

func get_parallel_lines(raycast_start: PathRaycast, raycast_end: PathRaycast) -> Array:
	var parallel_lines = []
	var distance: = raycast_start.global_position.distance_to(
		raycast_end.global_position)
	for end_direction in DIRECTIONS:
		for start_direction in DIRECTIONS:
			raycast_end.cast_to = end_direction * distance
			raycast_start.cast_to = start_direction * distance
			raycast_start.force_raycast_update()
			raycast_end.force_raycast_update()
			if not raycast_start.is_colliding() and not raycast_end.is_colliding():
				if start_direction == end_direction:
					var line1 = PoolVector2Array([
						raycast_start.global_position,
						raycast_start.cast_to])
					var line2 = PoolVector2Array([
						raycast_end.global_position,
						raycast_end.cast_to])
					parallel_lines.append([line1, line2])
	return parallel_lines

func raycasts_to_path(
	raycast1: RayCast2D, 
	raycast2: RayCast2D, 
	connecting_line: Line2D) -> PoolVector2Array:
		var path: = PoolVector2Array([
			raycast1.global_position,
			connecting_line.points[0],
			connecting_line.points[1],
			raycast2.cast_to
		])
		return path

	
