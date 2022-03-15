extends Node2D
class_name RaycastsPathfinder

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var grid: ConnectGameTilemap

func _ready() -> void:
	self.grid = get_parent()

func _create_raycast(cell: Vector2) -> PathRaycast:
	var raycast = PathRaycast.new()
	add_child(raycast)
	if grid.get_area2D_at(cell):
		raycast.add_exception(grid.get_area2D_at(cell))
	raycast.global_position = grid.to_global(
		grid.map_to_world(cell)) + grid.cell_size / 2
	
	return raycast

func is_raycast_within_board(raycast: PathRaycast) -> bool:
	var board: Rect2 = grid.get_rect_world()
	return board.has_point(raycast.global_position.abs()) and board.has_point(raycast.get_casting_global_pos().abs())

func _find_direct_path(
	raycast_start: PathRaycast, 
	raycast_end: PathRaycast) -> Array:
		var direction = raycast_start.global_position.direction_to(
			raycast_end.global_position)
		if direction in DIRECTIONS:
			raycast_start.cast_to = direction * raycast_start.global_position.distance_to(
				raycast_end.global_position)
			raycast_start.force_raycast_update()
			if not raycast_start.is_colliding():
				return [raycast_start.duplicate()]
		return []
		

# Gets a raycast and returns all the cells it passes through
func raycast_to_cells(raycast: PathRaycast) -> PoolVector2Array:
	var cells: = PoolVector2Array([])
	var start_point = grid.world_to_map(raycast.global_position)
	var end_point = grid.world_to_map(raycast.global_position + raycast.cast_to)
	var direction = raycast.cast_to.normalized()
	assert(direction in DIRECTIONS)
	var current_cell = start_point
	while current_cell != end_point and grid.is_within_board(current_cell):
		cells.append(current_cell)
		current_cell += direction
	cells.append(end_point)
	return cells

func _clear_raycasts() -> void:
	for child in get_children():
		if child is PathRaycast:
			child.queue_free()

static func are_parallel(vector1: Vector2, vector2: Vector2) -> bool:
	var angle = int(rad2deg(vector1.angle_to(vector2)))
	return angle == 0 or angle == 180

static func are_perpendicular(vector1: Vector2, vector2: Vector2) -> bool:
	return int(vector1.dot(vector2)) == 0

func get_path_length(path: Array) -> float:
	var length_sum: = 0.0
	for raycast in path:
		if raycast is PathRaycast:
			length_sum += raycast.get_length()
	return length_sum

func find_shortest_path(start: Vector2, end: Vector2) -> Array:
	_clear_raycasts()
	var possible_paths: Array = _find_possible_paths(start, end)
	var shortest_path: Array 
	if possible_paths:
		shortest_path = possible_paths.front()
		for path in possible_paths:
			if get_path_length(path) < get_path_length(shortest_path):
				shortest_path = path
	return shortest_path
	
func two_raycasts_to_line(raycast1: PathRaycast, raycast2: PathRaycast) -> Line2D:
	var line: = PathRaycast.create_line()
	line.add_point(raycast1.global_position)
	line.add_point(grid.map_to_world(_get_collision_cell(raycast1, raycast2)) + grid.cell_size / 2)
	line.add_point(raycast2.global_position)
	return line

func three_raycasts_to_line(raycast1: PathRaycast, raycast2: PathRaycast, connecting_raycast: PathRaycast) -> Line2D:
	var line: = PathRaycast.create_line()
	line.add_point(raycast1.global_position)
	line.add_point(connecting_raycast.global_position)
	line.add_point(connecting_raycast.get_casting_global_pos())
	line.add_point(raycast2.global_position)
	return line

func _find_possible_paths(start: Vector2, end: Vector2) -> Array:
	var raycast_start: = _create_raycast(start)
	var raycast_end: = _create_raycast(end)
	var possible_paths: Array = []
	raycast_start.add_exception(grid.get_area2D_at(end))
	raycast_end.add_exception(grid.get_area2D_at(start))
	
	var direct_path: Array = _find_direct_path(raycast_start, raycast_end)
	if direct_path:
		possible_paths.append(direct_path)
		return possible_paths
	
	for direction_start in DIRECTIONS:
		for direction_end in DIRECTIONS:
			raycast_start.cast_to = direction_start * grid.cell_size
			raycast_end.cast_to = direction_end * grid.cell_size
			raycast_start.force_raycast_update()
			raycast_end.force_raycast_update()
			var current_path = []
			if are_parallel(direction_start, direction_end):
				current_path = _find_path_with_parallel_raycasts(
					raycast_start, raycast_end)
			elif are_perpendicular(direction_start, direction_end):
				current_path = _find_path_with_perpendicular_raycasts(
					raycast_start, raycast_end)
			if current_path: 
				possible_paths.append(current_path)
	return possible_paths		
					
func _find_path_with_parallel_raycasts(
	raycast_start: PathRaycast, 
	raycast_end: PathRaycast) -> Array:
		var start_direction = raycast_start.cast_to.normalized()
		var end_direction = raycast_end.cast_to.normalized()
		
		while _can_extend_cast(raycast_start, start_direction * grid.cell_size):
			_extend_cast(raycast_start, start_direction * grid.cell_size)
		while _can_extend_cast(raycast_end, end_direction * grid.cell_size):
			_extend_cast(raycast_end, end_direction * grid.cell_size)
		var longer_raycast = raycast_start if raycast_start.get_length() >= raycast_end.get_length() else raycast_end
		var shorter_raycast = raycast_start if raycast_start.get_length() < raycast_end.get_length() else raycast_end
		var longer_cast_cells = raycast_to_cells(longer_raycast)
		var shorter_raycast_cells = raycast_to_cells(shorter_raycast)
		for long_cell in longer_cast_cells:
			for short_cell in shorter_raycast_cells:
				var connecting_raycast: = _create_raycast_between_cells(long_cell, short_cell)
				if not connecting_raycast.is_colliding() and connecting_raycast.cast_to.normalized() in DIRECTIONS:
					return [longer_raycast.duplicate(), shorter_raycast.duplicate(), connecting_raycast.duplicate()]
				else:
					connecting_raycast.queue_free()
		return []

func _create_raycast_between_cells(start: Vector2, end: Vector2) -> PathRaycast:
	var new_raycast = _create_raycast(start)
	var direction = start.direction_to(end)
	var distance = new_raycast.global_position.distance_to(
		grid.map_to_world(end) + grid.cell_size / 2)
	new_raycast.cast_to = direction * distance
	new_raycast.force_raycast_update()
	return new_raycast

func _can_extend_cast(raycast: PathRaycast, extend_by: Vector2) -> bool:
	return grid.get_rect_world().has_point(raycast.get_casting_global_pos() + extend_by) and (
		not raycast.is_colliding()) and (
		grid.get_cellv(grid.world_to_map(raycast.get_casting_global_pos() + extend_by)) == grid.INVALID_CELL)

func _extend_cast(raycast: PathRaycast, extend_by: Vector2) -> void:
	if _can_extend_cast(raycast, extend_by):
		raycast.cast_to += extend_by
		raycast.force_raycast_update()

func _get_collision_cell(raycast1: PathRaycast, raycast2: PathRaycast) -> Vector2:
	var raycast1_cells: Array = raycast_to_cells(raycast1)
	var raycast2_cells: Array = raycast_to_cells(raycast2)
	for current_cell in raycast1_cells:
		if raycast2_cells.find(current_cell) != -1:
			return current_cell
	return Vector2()
	
	
func _find_path_with_perpendicular_raycasts(
	raycast_start: PathRaycast, raycast_end: PathRaycast) -> Array:
		var path: = []
		var start_direction = raycast_start.cast_to.normalized()
		var end_direction = raycast_end.cast_to.normalized()
		while _can_extend_cast(raycast_start, start_direction * grid.cell_size) or (
			_can_extend_cast(raycast_end, end_direction * grid.cell_size)):
				_extend_cast(raycast_start, start_direction * grid.cell_size)
				_extend_cast(raycast_end, end_direction * grid.cell_size)
		if not raycast_start.is_colliding() and not raycast_end.is_colliding():
			var collision_point = _get_collision_cell(raycast_start, raycast_end)
			if collision_point:
				path = [raycast_start.duplicate(), raycast_end.duplicate()]
		return path
			
				
				
		
			
