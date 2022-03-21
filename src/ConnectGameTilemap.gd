extends TileMap
class_name ConnectGameTilemap

const EMPTY_TILE = -1
const DEFAULT_BOARD_SIZE = Vector2(3,3)
const TILE = preload("Tile.tscn")

export var board_size: = DEFAULT_BOARD_SIZE setget set_board_size
export var draw_border: = true
export var clear_path_after: float = 0.3

onready var debug_labels = owner.get_node("UI/DebugLabels")
onready var pathfinder = $RaycastsPathfinder

signal pair_cleared(pair)
signal misplay

var selected_cell

var _tiles_areas2D: Dictionary = {}

func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	update()
	debug_labels.set_label("mouse_cell", get_mouse_cell() as String)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click") or (event is InputEventScreenTouch):
		var cell_clicked = _get_cell_clicked(event)
		if get_cellv(cell_clicked) != INVALID_CELL:
			if not selected_cell:
				selected_cell = cell_clicked
			elif selected_cell == cell_clicked:
				selected_cell = null
			else:
				var path: PathData = find_path(selected_cell, cell_clicked)
				if path:
					draw_path(path.get_line_path())
					var pair = TilesPair.new(selected_cell, cell_clicked)
					remove_pair(pair)
					emit_signal("pair_cleared", pair)
				else:
					emit_signal("misplay")
				selected_cell = null

func _get_cell_clicked(event: InputEvent) -> Vector2:
	if event is InputEventMouseButton and event.is_action_pressed("click"):
		return get_mouse_cell()
	elif event is InputEventScreenTouch:
		return to_global(world_to_map(event.position))
	else:
		return Vector2.INF

func start_new_game(board_size_: Vector2 = DEFAULT_BOARD_SIZE) -> void:
	self.board_size = board_size_
	if not get_parent().debug_mode:
		setup_board()
	else:
		setup_board_debug_mode()
	$Hint.remove_hint()
	$Camera2D.position = get_rect_world().position + get_rect_world().size / 2

func find_path(from: Vector2, to: Vector2) -> PathData:
	var path: PathData
	if get_cellv(from) == get_cellv(to):
		path = pathfinder.find_shortest_path(from, to)
	return path

func draw_path(points: PoolVector2Array, time_on_screen: float = clear_path_after) -> void:
	var line: = PathRaycast.create_line()
	for point in points:
		line.add_point(point)
	add_child(line)
	if sign(time_on_screen) == 1:	
	# warning-ignore:return_value_discarded
		get_tree().create_timer(time_on_screen).connect("timeout", line, "queue_free")
	
func as_index(cell: Vector2) -> int:
	return int(cell.x + cell_size.x * cell.y)
	
func display_hint() -> void:
	var possible_paths = get_all_possible_paths().values()
	var hint_path: PathData = get_random_array_element(possible_paths)
	$Hint.show_hint(hint_path)
	

func get_connectable_pairs() -> Array:
	var connectables = []
	for pair in get_all_pairs():
		if find_path(pair.tile1_cords, pair.tile2_cords):
			connectables.append(pair)
	return connectables

func shuffle_board() -> void:
	var all_cells = get_used_cells()
	while not all_cells.empty():
		var cell1 = all_cells.pop_front()
		all_cells.shuffle()
		var cell1_tile = get_cellv(cell1)
		var cell2 = all_cells.pop_front()
		all_cells.shuffle()
		var cell2_tile = get_cellv(cell2)
		set_cellv(cell1, cell2_tile)
		set_cellv(cell2, cell1_tile)
		
func swap_pairs(pair1: TilesPair, pair2: TilesPair) -> void:
	var pair1_tile_id = get_cellv(pair1.tile1_cords)
	var pair2_tile_id = get_cellv(pair2.tile1_cords)
	for cord in pair1.as_array():
		set_cellv(cord, pair2_tile_id)
	for cord in pair2.as_array():
		set_cellv(cord, pair1_tile_id)

func remove_pair(pair: TilesPair) -> void:
	set_cellv(pair.tile1_cords, EMPTY_TILE)
	set_cellv(pair.tile2_cords, EMPTY_TILE)
	disable_cell_collision(pair.tile1_cords)
	disable_cell_collision(pair.tile2_cords)

func get_all_possible_paths() -> Dictionary:
	var paths: = {}
	for pair in get_all_pairs():
		if pair is TilesPair:
			var possible_path = find_path(pair.tile1_cords, pair.tile2_cords)
			if possible_path:
				paths[pair] = possible_path
	return paths

func has_possible_paths() -> bool:
	for pair in get_all_pairs():
		if pair is TilesPair:
			var possible_path = find_path(pair.tile1_cords, pair.tile2_cords)
			if possible_path:
				return true
	return false
	
func get_all_pairs() -> Array:
	var pairs: = []
	for tile_id in tile_set.get_tiles_ids():
		pairs.append_array(get_all_pairs_of(tile_id))
	return pairs

func get_all_pairs_of(tile_id: int) -> Array:
	var cells: Array = get_used_cells_by_id(tile_id)
	var pairs: Array = []
	for idx in cells.size() - 1:
		var new_pair = TilesPair.new(cells[idx], cells[idx + 1])
		assert(get_cellv(new_pair.tile1_cords) == get_cellv(new_pair.tile2_cords))
		pairs.append(new_pair)
	return pairs

func _draw() -> void:
	var mouse_cell = get_mouse_cell()
	if get_cellv(mouse_cell) != INVALID_CELL and get_cellv(mouse_cell) != EMPTY_TILE:
		draw_rect(
			Rect2(map_to_world(mouse_cell), cell_size),
			Color.white,
			false
		)
	if selected_cell:
		draw_rect(
			Rect2(map_to_world(selected_cell), cell_size),
			Color.yellowgreen,
			false,
			2
		)
	if get_parent().debug_mode:
		draw_rect(
			get_rect_world(), 
			Color.white,
			false,
			2
		)
		for y in board_size.y + 1:
			for x in board_size.x + 1:
				if is_border_cell(Vector2(x,y)):
					draw_rect(
					Rect2(map_to_world(Vector2(x,y)), cell_size),
					Color.gray)

func set_board_size(val: Vector2) -> void:
	if not (int(val.x * val.y) % 2 == 0):
		val.x += 1
	board_size = val + Vector2.ONE

func setup_board_debug_mode() -> void:
	for cell in get_used_cells():
		_add_collision(cell)

func setup_board() -> void:
	clear()
	_setup_colllision()
	fill_board()

func fill_board() -> void:
	var free_cells: Array = get_free_cells(false)
	assert(free_cells.size() % 2 == 0)
	while not free_cells.empty():
		var cell1 = free_cells.pop_at(int(rand_range(0, free_cells.size() - 1)))
		var cell2 = free_cells.pop_at(int(rand_range(0, free_cells.size() - 1)))
		var tile_id = get_random_tile()
		set_cellv(cell1, tile_id)
		set_cellv(cell2, tile_id)

func get_rect() -> Rect2:
	return Rect2(Vector2.ZERO, board_size)

func get_rect_world() -> Rect2:
	return Rect2(global_position, board_size * cell_size + cell_size)

func is_border_cell(cords: Vector2) -> bool:
	return (
		cords.x == 0 or cords.x == board_size.x) or (
		cords.y == 0 or cords.y == board_size.y)	

func is_within_board(cell: Vector2) -> bool:
	return get_used_rect().has_point(cell) or is_border_cell(cell)
			
func get_random_tile() -> int:
	var all_tiles = tile_set.get_tiles_ids()
	all_tiles.erase(EMPTY_TILE)
	return get_random_array_element(all_tiles)

func get_cells_for_path(from: Vector2, to: Vector2) -> PoolVector2Array:
	var cells: PoolVector2Array = [from, to]
	cells.append_array(get_free_cells(true))
	return cells

func get_all_cells(include_border: = true) -> PoolVector2Array:
	var cells: PoolVector2Array = []
	for y in board_size.y + 1:
		for x in board_size.x + 1:
			var current_cell = Vector2(x,y)
			if is_border_cell(current_cell):
					if include_border: cells.append(current_cell)
			else:
				cells.append(current_cell)
	return cells
	
func get_free_cells(include_border: = false) -> PoolVector2Array:
	var cells: PoolVector2Array = []
	for cell in get_all_cells(include_border):
		if get_cellv(cell) == EMPTY_TILE or get_cellv(cell) == INVALID_CELL:
			cells.append(cell)
	return cells

func get_mouse_pos() -> Vector2:
	return get_global_mouse_position()

func get_mouse_cell() -> Vector2:
	return world_to_map(to_local(get_mouse_pos()))

func get_area2D_at(cell: Vector2) -> Area2D:
	return _tiles_areas2D.get(cell, null)

func disable_cell_collision(cell: Vector2) -> void:
	var collision_area: Area2D = get_area2D_at(cell)
	collision_area.shape_owner_set_disabled(0, true)
	collision_area.visible = false

func check_win() -> bool:
	return get_used_cells().empty()

func _add_collision(cell: Vector2) -> void:
	var new_tile_area = TILE.instance()
	add_child(new_tile_area)
	new_tile_area.add_to_group("tile_areas")
	new_tile_area.setup(
		cell_size,
		map_to_world(cell) + cell_size / 2)
	_tiles_areas2D[cell] = new_tile_area
	#new_tile_area.visible = get_parent().debug_mode

func _setup_colllision() -> void:
	_tiles_areas2D = {}
	for node in get_tree().get_nodes_in_group("tile_areas"):
		node.queue_free()
	for cell in get_all_cells(false):
		_add_collision(cell)

static func get_random_array_element(array: Array):
	var copy = array.duplicate()
	copy.shuffle()
	return copy.front()
