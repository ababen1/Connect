extends TileMapLayer
class_name ConnectGameTilemap

const EMPTY_TILE = -1
const DEFAULT_BOARD_SIZE = Vector2i(5,6)
const TILE = preload("Tile.tscn")

@export var board_size: = DEFAULT_BOARD_SIZE: set = set_board_size
@export var draw_border: = true
@export var clear_path_after: float = 0.3
@export var include_catagories: Array[String]

signal pair_cleared(pair)
signal misplay

var selected_cell: Vector2i 
var _tiles_areas2D: Dictionary = {}
var pathfinder: = OnetPathfinder.new(self)

func _ready() -> void:
	changed.connect(func(): $Camera2D.position = get_rect_world().get_center())
	if get_tree().current_scene == self:
		setup_board()
				
func _process(_delta: float) -> void:
	queue_redraw()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
		var cell_clicked = get_mouse_cell()
		if get_cellv(cell_clicked) != EMPTY_TILE:
				if not selected_cell:
					selected_cell = cell_clicked
				elif selected_cell == cell_clicked:
					selected_cell = Vector2i.ZERO
				else:
					var path: Array = find_path(selected_cell, cell_clicked)
					if path:
						#draw_path(path.get_line_path())
						print("valid!")
						var pair = TilesPair.new(selected_cell, cell_clicked)
						remove_pair(pair)
						emit_signal("pair_cleared", pair)
					else:
						emit_signal("misplay")
					selected_cell = Vector2i.ZERO

func get_cellv(cell_clicked: Vector2) -> int:
	return get_cell_source_id(Vector2i(cell_clicked))

func set_cellv(cell: Vector2, value: int) -> void:
	set_cell(cell, value)

func get_possible_tiles_of_categories(categories: Array[String]) -> Array[TileData]:
	var tiles: Array[TileData] = []
	for tile: TileData in TileMapFuncs.get_possible_tiles(tile_set):
		print(tile.get_custom_data("category"))
		if tile.get_custom_data("category") in categories:
			tiles.append(tile)
	return tiles

func start_new_game(board_size_: Vector2 = DEFAULT_BOARD_SIZE) -> void:
	self.board_size = board_size_
	$Hint.remove_hint()

func find_path(from: Vector2i, to: Vector2i) -> Array:
	var path: Array = []
	## Check if the selected cells have the same icon
	if TileMapFuncs.are_tiles_same(self, from, to):
		path = pathfinder.find_path_from_map_coords(from,to)
	return path

func draw_path(points: PackedVector2Array, time_on_screen: float = clear_path_after) -> void:
	var line: = PathRaycast.create_line()
	for point in points:
		line.add_point(point)
	add_child(line)
	if sign(time_on_screen) == 1:	
	# warning-ignore:return_value_discarded
		get_tree().create_timer(time_on_screen).connect("timeout", Callable(line, "queue_free"))
	
func display_hint() -> void:
	var possible_paths = get_all_possible_paths().values()
	var hint_path: PathData = possible_paths.pick_random()
	$Hint.show_hint(hint_path)
	

func get_connectable_pairs() -> Array:
	var connectables = []
	for pair in get_all_pairs():
		if find_path(pair.tile1_cords, pair.tile2_cords):
			connectables.append(pair)
	return connectables

func shuffle_board() -> void:
	var all_cells = get_used_cells()
	while not all_cells.is_empty():
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
	## Draw outline around the hovered cell
	var mouse_cell = get_mouse_cell()
	if get_cellv(mouse_cell) != EMPTY_TILE:
		draw_rect(
			Rect2(map_to_local(mouse_cell) - Vector2(tile_set.tile_size) / 2.0, tile_set.tile_size),
			Color.WHITE,
			false
		)
	
	## Draw an outline around the selected (clicked) cell	
	if selected_cell:
		draw_rect(
			Rect2(map_to_local(selected_cell) - Vector2(tile_set.tile_size) / 2.0, tile_set.tile_size),
			Color.YELLOW_GREEN,
			false,
			2
		)
	if draw_border and Engine.is_embedded_in_editor():
		draw_rect(
			get_rect_world(), 
			Color.WHITE,
			false,
			2
		)
		#for y in board_size.y + 1:
			#for x in board_size.x + 1:
				#if is_border_cell(Vector2(x,y)):
					#draw_rect(
					#Rect2(map_to_local(Vector2(x,y)), tile_set.tile_size),
					#Color.GRAY)

func set_board_size(val: Vector2) -> void:
	if not (int(val.x * val.y) % 2 == 0):
		val.x += 1
	board_size = val + Vector2.ONE

func setup_board() -> void:
	clear()
	fill_board()

## Inital board setup - fill the board with pairs
func fill_board() -> void:
	var free_cells: Array = get_free_cells(false)
	assert(free_cells.size() % 2 == 0)
	var possible_tiles: = get_possible_tiles_of_categories(include_catagories)
	while not free_cells.is_empty():
		var cell1 = free_cells.pop_at(int(randf_range(0, free_cells.size() - 1)))
		var cell2 = free_cells.pop_at(int(randf_range(0, free_cells.size() - 1)))
		var tile: TileData = possible_tiles.pick_random()
		set_cell(cell1, tile.get_meta("source_id", -1), tile.get_meta("atlas_coords"))
		set_cell(cell2, tile.get_meta("source_id", -1), tile.get_meta("atlas_coords"))
		possible_tiles.erase(tile)

func get_rect() -> Rect2:
	return Rect2(Vector2.ZERO, board_size)

func get_rect_world() -> Rect2:
	return Rect2(global_position, board_size * tile_set.tile_size + tile_set.tile_size)

func is_border_cell(cords: Vector2) -> bool:
	return (
		cords.x == 0 or cords.x == board_size.x) or (
		cords.y == 0 or cords.y == board_size.y)	

func is_within_board(cell: Vector2) -> bool:
	return get_used_rect().has_point(cell) or is_border_cell(cell)

func get_cells_for_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var cells: PackedVector2Array = [from, to]
	cells.append_array(get_free_cells(true))
	return cells

func get_all_cells(include_border: = true) -> PackedVector2Array:
	var cells: PackedVector2Array = []
	for y in board_size.y + 1:
		for x in board_size.x + 1:
			var current_cell = Vector2(x,y)
			if is_border_cell(current_cell):
					if include_border: cells.append(current_cell)
			else:
				cells.append(current_cell)
	return cells
	
func get_free_cells(include_border: = false) -> PackedVector2Array:
	var cells: PackedVector2Array = []
	for cell in get_all_cells(include_border):
		if get_cellv(cell) == EMPTY_TILE:
			cells.append(cell)
	return cells

func get_mouse_pos() -> Vector2:
	return get_global_mouse_position()

func get_mouse_cell() -> Vector2i:
	return local_to_map(to_local(get_mouse_pos()))

func get_area2D_at(cell: Vector2) -> Area2D:
	return _tiles_areas2D.get(cell, null)

func check_win() -> bool:
	return get_used_cells().is_empty()
