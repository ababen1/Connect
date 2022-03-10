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
	clear_raycasts()
	if end < start:
		var temp = start
		start = end
		end = temp
	var raycast_start: = create_raycast(start)
	var raycast_end: = create_raycast(end)
	raycast_start.add_exception(grid.get_area2D_at(end))
	raycast_end.add_exception(grid.get_area2D_at(start))
	
	var direct_path = find_direct_path(raycast_start, raycast_end)
	if direct_path:
		return direct_path
		
	for direction in get_possible_directions(raycast_start, raycast_end):
		raycast_start.cast_to = direction * grid.get_used_rect_world().size
		raycast_end.cast_to = direction * grid.get_used_rect_world().size
		raycast_start.force_raycast_update()
		raycast_end.force_raycast_update()
		var connecting_raycast = get_connecting_raycast(raycast_start, raycast_end)
		if connecting_raycast:
			var path = raycasts_to_path(
				raycast_start, raycast_end, connecting_raycast)
			path.push_back(end)
			path.insert(0, start)
			return path
				
	return PoolVector2Array([])

func is_raycast_within_board(raycast: PathRaycast) -> bool:
	var board: Rect2 = grid.get_used_rect_world(true)
	return board.has_point(raycast.global_position.abs()) and board.has_point(raycast.cast_to.abs())

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

# tries to find a path without using a third raycast
#func find_path_with_two_raycasts(
#	raycast_start: PathRaycast, 
#	raycast_end: PathRaycast) -> PoolVector2Array:
#		var path = PoolVector2Array([])
#		var distance = raycast_start.global_position.distance_to(raycast_end.global_position)
#		for direction_start in DIRECTIONS:
#			for direction_end in DIRECTIONS:
#				raycast_start.cast_to = direction_start * distance
#				raycast_end.cast_to = direction_end * distance
#				raycast_start.force_raycast_update()
#				raycast_end.force_raycast_update()
#
#		return path

# gets two parallel raycasts and tries to create a third raycast that connects them
func get_connecting_raycast(
	raycast_start: PathRaycast, 
	raycast_end: PathRaycast) -> PathRaycast:
		assert(raycast_start.cast_to.normalized() == raycast_end.cast_to.normalized())
		var direction: Vector2 = raycast_start.cast_to.normalized()
		var perpendicular_direction: = Vector2(-direction.y, direction.x)
		
		var connecting_raycast: = create_raycast(
			grid.world_to_map(raycast_start.global_position))
		connecting_raycast.cast_to = perpendicular_direction * (
			raycast_start.global_position.distance_to(
			raycast_end.global_position))
		if not connecting_raycast.global_position + connecting_raycast.cast_to == raycast_end.global_position:
				connecting_raycast.cast_to *= -1
				
		connecting_raycast.force_raycast_update()
		while(is_raycast_within_board(connecting_raycast)):
			if not connecting_raycast.is_colliding():
				return connecting_raycast
			connecting_raycast.global_position += direction * grid.cell_size
			connecting_raycast.force_raycast_update()
		return null
		

# Look for directions that when a 
# ray is cast toward that direction, there is no collision
func get_possible_directions(
	raycast_start: PathRaycast, 
	raycast_end: PathRaycast) -> PoolVector2Array:
		var possible_directions = []
		var distance: = raycast_start.global_position.distance_to(
			raycast_end.global_position)
		for direction in DIRECTIONS:
			raycast_end.cast_to = direction * distance
			raycast_start.cast_to = direction * distance
			raycast_start.force_raycast_update()
			raycast_end.force_raycast_update()
			if not raycast_start.is_colliding() and not raycast_end.is_colliding():
				possible_directions.append(direction)
		return possible_directions

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

func raycasts_to_path(
	raycast_start: RayCast2D, 
	raycast_end: RayCast2D, 
	connecting_raycast: RayCast2D) -> PoolVector2Array:
		var path: = raycast_to_cells(raycast_start)
		path.append_array(raycast_to_cells(connecting_raycast))
		path.append_array(raycast_to_cells(raycast_end))
		return path

func clear_raycasts() -> void:
	for child in get_children():
		if child is PathRaycast:
			child.queue_free()

static func are_parallel(vector1: Vector2, vector2: Vector2) -> bool:
	var angle = rad2deg(vector1.angle_to(vector2))
	return angle == 0 or angle == 180

static func are_perpendicular(vector1: Vector2, vector2: Vector2) -> bool:
	return vector1.dot(vector2) == 0

func find_path_attempt2(start: Vector2, end: Vector2):
	clear_raycasts()
	if end < start:
		var temp = start
		start = end
		end = temp
	var raycast_start: = create_raycast(start)
	var raycast_end: = create_raycast(end)
	var connecting_raycast: = create_raycast(start)
	raycast_start.add_exception(grid.get_area2D_at(end))
	raycast_end.add_exception(grid.get_area2D_at(start))
	var path = PoolVector2Array([])
	var distance = grid.cell_size
	for direction_start in DIRECTIONS:
		for direction_end in DIRECTIONS:
			raycast_start.cast_to = direction_start * distance
			raycast_end.cast_to = direction_end * distance
			raycast_start.force_raycast_update()
			raycast_end.force_raycast_update()
			if not raycast_start.is_colliding() and not raycast_end.is_colliding():
				if are_parallel(direction_start, direction_end):
					_find_path_with_parallel_raycasts(raycast_start, raycast_end)
				elif are_perpendicular(direction_start, direction_end):
					_find_path_with_perpendicular_raycasts(raycast_start, raycast_end)

func _find_path_with_parallel_raycasts(
	raycast_start: PathRaycast, 
	raycast_end: PathRaycast) -> PoolVector2Array:
		var start_direction = raycast_start.cast_to.normalized()
		var end_direction = raycast_end.cast_to.normalized()
		
		while is_raycast_within_board(raycast_start) and (
			is_raycast_within_board(raycast_end) and (
			not raycast_start.is_colliding() and (
			not raycast_end.is_colliding()))):
				if raycast_start.get_casting_global_pos().direction_to(
					raycast_end.get_casting_global_pos()) in DIRECTIONS:
						var connecting_raycast = get_connecting_raycast(
							raycast_start, raycast_end)
						return raycasts_to_path(
							raycast_start, raycast_end, connecting_raycast)
				raycast_start.cast_to += start_direction * grid.cell_size
				raycast_end.cast_to += end_direction * grid.cell_size
		return PoolVector2Array([])
	
func _find_path_with_perpendicular_raycasts(
	raycast_start: PathRaycast, raycast_end: PathRaycast):
		pass
