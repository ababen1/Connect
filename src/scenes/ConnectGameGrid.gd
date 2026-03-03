extends TileMapLayer
class_name ConnectGameGrid

const DEFAULT_BOARD_SIZE = Vector2i(5,6)

@export var board_size: Vector2i = DEFAULT_BOARD_SIZE: set = set_board_size
@export var draw_border: = true
@export var clear_path_after: float = 0.3
@export var include_catagories: Array[String]
## A template for a line2D that will be used to display the path
@export var line_template: Line2D

@onready var hint_line: Line2D = %HintLine

signal pair_cleared(pair)
signal misplay
signal board_cleared
signal path_animation_finished(path: Line2D)

var selected_cell: Vector2i 
var _tiles_areas2D: Dictionary = {}
var pathfinder: = OnetPathfinder.new(self)

func _ready() -> void:
	path_animation_finished.connect(func(l: Line2D): l.queue_free())
	if get_tree().current_scene == self:
		setup_board()
				
func _process(_delta: float) -> void:
	queue_redraw()
		
func _unhandled_input(event: InputEvent) -> void:
	#region Debugging shortcuts
	if OS.is_debug_build(): 
		if Input.is_action_just_pressed("ui_home"):
			shuffle_board()
		if Input.is_action_just_pressed("ui_end"):
			setup_board()
	
	#endregion 
	if event.is_action_pressed("click") or event.is_action_pressed("ui_accept"):
		var cell_clicked = get_mouse_cell()
		if not TileMapFuncs.is_empty_cell(self, cell_clicked):
				if not selected_cell:
					selected_cell = cell_clicked
				elif selected_cell == cell_clicked:
					selected_cell = Vector2i.ZERO
				else:
					var path: Array[Vector2i] = find_path(selected_cell, cell_clicked)
					if path:
						var pair = PairData.new(
							selected_cell, cell_clicked, TileIdentifiers.from_tilemap(selected_cell, self))
						_handle_pair_cleared(pair, path)
					else:
						misplay.emit()
					selected_cell = Vector2i.ZERO

func center_camera() -> void:
	$Camera2D.position = get_rect_world().get_center()	
	
func get_possible_tiles_of_categories(categories: Array[String]) -> Array[TileData]:
	var tiles: Array[TileData] = []
	for tile: TileData in TileMapFuncs.get_possible_tiles(tile_set):
		if tile.get_custom_data("category") in categories:
			tiles.append(tile)
	return tiles

func start_new_game(board_size_: Vector2 = DEFAULT_BOARD_SIZE) -> void:
	hint_line.hide()
	set_board_size(board_size_)
	setup_board()
	_check_for_shuffle()

func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	## Check if the selected cells have the same icon
	if TileMapFuncs.are_tiles_same(self, from, to):
		path = pathfinder.find_path_from_map_coords(from,to)
	return path

func draw_path(points: Array[Vector2i], time_on_screen: float = clear_path_after) -> void:
	var line: = _create_line(line_template, points)
	add_child(line)
	line.create_tween().tween_property(line, "modulate:a", 1.0, 0.1).from(0.0)
	if time_on_screen > 0:
		await get_tree().create_timer(time_on_screen).timeout
	else:
		await get_tree().process_frame
	line.queue_free()

func display_hint() -> void:
	_setup_line(hint_line, get_all_possible_paths().values().pick_random())
	pair_cleared.connect(func(_pair): 
		hint_line.hide(), CONNECT_ONE_SHOT)
	

func shuffle_board() -> void:
	var all_cells = get_used_cells()
	if all_cells.size() < 2:
		return  # No need to shuffle if there are fewer than 2 tiles

	all_cells.shuffle()  # randomize their order

	# Perform a number of random swaps
	var swap_count = randi_range(5,10)  # Adjust this number to increase or decrease the shuffling
	for i in range(swap_count):
		var cell1_index = randi() % all_cells.size()
		var cell2_index = randi() % all_cells.size()

		var cell1 = all_cells[cell1_index]
		var cell2 = all_cells[cell2_index]

		var cell1_tile = TileIdentifiers.from_tilemap(cell1, self)
		var cell2_tile = TileIdentifiers.from_tilemap(cell2, self)

		set_cell(cell1, cell2_tile.source_id, cell2_tile.atlas_coords)
		set_cell(cell2, cell1_tile.source_id, cell1_tile.atlas_coords)

	pathfinder.sync_grid_to_tilemap()



func remove_pair(pair: PairData) -> void:
	set_cell(pair.cell1, -1)
	set_cell(pair.cell2, -1)

## Returns an array of all the types of tiles currently in the tilemap. (For example, all the food items)
func get_all_tiles_types() -> Array[Dictionary]:
	var types: Array[Dictionary] = []
	for cell in get_used_cells():
		var current_tile: Dictionary = TileIdentifiers.from_tilemap(cell, self).to_dict()
		if !(current_tile in types):
			types.append(current_tile)
	return types

## Returns all the cells with a given tile identifiers
func get_cells_of_type(type: Dictionary) -> Array[Vector2i]:
	return get_used_cells().filter(func(x: Vector2i): 
		return TileIdentifiers.from_tilemap(x, self).to_dict() == type)

func get_all_pairs() -> Array[PairData]:
	var pairs: Array[PairData] = []
	for type: Dictionary in get_all_tiles_types():
		var cells_of_type: = get_cells_of_type(type)
		if cells_of_type.size() % 2 != 0:
			printerr("Error: there is a solo tile of type ", type)
		else:
			while not cells_of_type.is_empty():
				pairs.append(PairData.new
				(cells_of_type.pop_front(), 
				cells_of_type.pop_front(), 
				TileIdentifiers.from_dict(type)))
	return pairs
		
		

## Dictionary[PairData: Array[Vector2i]]
func get_all_possible_paths() -> Dictionary:
	var paths: = {}
	for pair: PairData in get_all_pairs():
		var possible_path: Array[Vector2i] = find_path(pair.cell1, pair.cell2)
		if possible_path:
			paths[pair] = possible_path
	return paths

func has_possible_paths() -> bool:
	return not get_all_possible_paths().is_empty()

func _setup_line(line: Line2D, grid_points: Array[Vector2i]) -> void:
	line.clear_points()
	line.show()
	line.position = Vector2.ZERO
	for p in grid_points:
		line.add_point(map_to_local(p))

func _create_line(template: Line2D, points: Array[Vector2i]) -> Line2D:
	var line: = template.duplicate()
	_setup_line(line, points)
	return line

func _draw() -> void:
	## Draw outline around the hovered cell
	var mouse_cell = get_mouse_cell()
	if not TileMapFuncs.is_empty_cell(self, mouse_cell):
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

func set_board_size(val: Vector2i) -> void:
	if not (int(val.x * val.y) % 2 == 0):
		val.x += 1
	board_size = val

func setup_board() -> void:
	clear()
	fill_board()
	center_camera()

## Inital board setup - fill the board with pairs
func fill_board() -> void:
	var free_cells: Array = get_free_cells()
	assert(free_cells.size() % 2 == 0)
	var possible_tiles: = get_possible_tiles_of_categories(include_catagories)
	while not free_cells.is_empty():
		var cell1 = free_cells.pop_at(int(randf_range(0, free_cells.size() - 1)))
		var cell2 = free_cells.pop_at(int(randf_range(0, free_cells.size() - 1)))
		var tile: TileData = possible_tiles.pick_random()
		var tile_identifiers: = TileMapFuncs.get_identifiers_from_meta(tile)
		set_cell(cell1, tile_identifiers.source_id, tile_identifiers.atlas_coords)
		set_cell(cell2, tile_identifiers.source_id, tile_identifiers.atlas_coords)
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
	cells.append_array(get_free_cells())
	return cells

func get_all_cells() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in board_size.y:
		for x in board_size.x:
			cells.append(Vector2i(x,y))
	return cells
	
func get_free_cells() -> Array[Vector2i]:
	var cells:  Array[Vector2i] = []
	for cell: Vector2i in get_all_cells():
		if TileMapFuncs.is_empty_cell(self, cell):
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

func _handle_pair_cleared(pair: PairData, path: Array[Vector2i]) -> void:	
		await draw_path(path)
		remove_pair(pair)
		pair_cleared.emit(pair)
		if check_win():
			board_cleared.emit()
		else:
			_check_for_shuffle()
				

func _check_for_shuffle() -> void:
	var attempts = 100
	while !has_possible_paths() and attempts > 0:
		shuffle_board()
		attempts -= 1
	if attempts <= 0:
		print("No possible path found after 100 shuffles!")
