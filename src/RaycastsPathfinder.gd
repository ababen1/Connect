extends Node2D
class_name RaycastsPathfinder

const DIRECTIONS = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]

var grid: ConnectGameTilemap

func _ready() -> void:
	self.grid = get_parent()

func _create_raycast(cell: Vector2) -> PathRaycast:
	var raycast = PathRaycast.new()
	add_child(raycast)
	raycast.add_exception(grid.get_area2D_at(cell))
	raycast.global_position = grid.to_global(
		grid.map_to_world(cell)) + grid.cell_size / 2
	
	return raycast

func is_raycast_within_board(raycast: PathRaycast) -> bool:
	var board: Rect2 = grid.get_rect_world()
	return board.has_point(raycast.global_position.abs()) and board.has_point(raycast.get_casting_global_pos().abs())

func find_direct_path(
	raycast_start: PathRaycast, 
	raycast_end: PathRaycast) -> PoolVector2Array:
		var direction = raycast_start.global_position.direction_to(
			raycast_end.global_position)
		if direction in DIRECTIONS:
			raycast_start.cast_to = direction * raycast_start.global_position.distance_to(
				raycast_end.global_position)
			raycast_start.force_raycast_update()
			if not raycast_start.is_colliding():
				return raycast_to_cells(raycast_start)
		return PoolVector2Array([])

# gets two parallel raycasts and tries to create a third raycast that connects them
func get_connecting_raycast(
	raycast_start: PathRaycast, 
	raycast_end: PathRaycast) -> PathRaycast:
		var connecting_raycast: PathRaycast = null
		if raycast_start.get_casting_global_pos().direction_to(raycast_end.get_casting_global_pos()) in DIRECTIONS:
			connecting_raycast = _create_raycast(
				grid.world_to_map(raycast_start.get_casting_global_pos()))
			connecting_raycast.cast_to = (
				raycast_start.get_casting_global_pos().direction_to(
				raycast_end.get_casting_global_pos())) * (
				raycast_start.get_casting_global_pos().distance_to(
				raycast_end.get_casting_global_pos()))
			connecting_raycast.force_raycast_update()
			if connecting_raycast.is_colliding():
				connecting_raycast.queue_free()
				connecting_raycast = null
		return connecting_raycast
		

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

func three_raycasts_to_path(
	raycast_start: RayCast2D, 
	raycast_end: RayCast2D, 
	connecting_raycast: RayCast2D) -> PoolVector2Array:
		var path: = raycast_to_cells(raycast_start)
		if connecting_raycast:
			path.append_array(raycast_to_cells(connecting_raycast))
		path.append_array(raycast_to_cells(raycast_end))
		return path

func two_raycasts_to_path(start: PathRaycast, end: PathRaycast) -> PoolVector2Array:
	var end_cells: Array = raycast_to_cells(end)
	end_cells.invert()
	var start_cells: Array = raycast_to_cells(start)
	var common_cell = _get_collision_cell(start, end)
	var path: Array = []
	var current_cell: Vector2
	while current_cell != common_cell:
		current_cell = start_cells.pop_front()
		path.append(current_cell)
	end_cells = end_cells.slice(
		end_cells.find(common_cell), 
		end_cells.find(grid.world_to_map(end.global_position)))
	path.append_array(end_cells)
	
	return path as PoolVector2Array

func clear_raycasts() -> void:
	for child in get_children():
		if child is PathRaycast:
			child.queue_free()

static func are_parallel(vector1: Vector2, vector2: Vector2) -> bool:
	var angle = int(rad2deg(vector1.angle_to(vector2)))
	return angle == 0 or angle == 180

static func are_perpendicular(vector1: Vector2, vector2: Vector2) -> bool:
	return int(vector1.dot(vector2)) == 0

func find_shortest_path(start: Vector2, end: Vector2) -> PoolVector2Array:
	clear_raycasts()
	var raycast_start: = _create_raycast(start)
	var raycast_end: = _create_raycast(end)
	raycast_start.add_exception(grid.get_area2D_at(end))
	raycast_end.add_exception(grid.get_area2D_at(start))
	
	var direct_path = find_direct_path(raycast_start, raycast_end)
	if direct_path:
		return direct_path
	
	for direction_start in DIRECTIONS:
		for direction_end in DIRECTIONS:
			raycast_start.cast_to = direction_start * grid.cell_size
			raycast_end.cast_to = direction_end * grid.cell_size
			raycast_start.force_raycast_update()
			raycast_end.force_raycast_update()
			if are_parallel(direction_start, direction_end):
				var path = _find_path_with_parallel_raycasts(
					raycast_start, raycast_end)
				if path: return path
			elif are_perpendicular(direction_start, direction_end):
				var path = _find_path_with_perpendicular_raycasts(
					raycast_start, raycast_end)
				if path: return path
	return PoolVector2Array([])				
					
func _find_path_with_parallel_raycasts(
	raycast_start: PathRaycast, 
	raycast_end: PathRaycast) -> PoolVector2Array:
		var start_direction = raycast_start.cast_to.normalized()
		var end_direction = raycast_end.cast_to.normalized()
		
		var connecting_raycast = get_connecting_raycast(raycast_start, raycast_end)
		if connecting_raycast:
			return three_raycasts_to_path(raycast_start, raycast_end, connecting_raycast)
		
		while (
			_can_extend_cast(raycast_start, start_direction * grid.cell_size) or (
			_can_extend_cast(raycast_end, end_direction * grid.cell_size))) and (
			not raycast_start.is_colliding() and (
			not raycast_end.is_colliding())):
				_extend_cast(raycast_start, start_direction * grid.cell_size)
				_extend_cast(raycast_end, end_direction * grid.cell_size)
				connecting_raycast = get_connecting_raycast(raycast_start, raycast_end)
				if connecting_raycast:
					return three_raycasts_to_path(raycast_start, raycast_end, connecting_raycast)
		return PoolVector2Array([])

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
	raycast_start: PathRaycast, raycast_end: PathRaycast) -> PoolVector2Array:
		var path: = PoolVector2Array([])
		var start_direction = raycast_start.cast_to.normalized()
		var end_direction = raycast_end.cast_to.normalized()
		while _can_extend_cast(raycast_start, start_direction * grid.cell_size) or (
			_can_extend_cast(raycast_end, end_direction * grid.cell_size)):
				_extend_cast(raycast_start, start_direction * grid.cell_size)
				_extend_cast(raycast_end, end_direction * grid.cell_size)
		if not raycast_start.is_colliding() and not raycast_end.is_colliding():
			var collision_point = _get_collision_cell(raycast_start, raycast_end)
			if collision_point:
				path = two_raycasts_to_path(raycast_start, raycast_end)
		return path
			
				
				
		
			
