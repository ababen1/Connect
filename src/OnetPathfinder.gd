extends Node
class_name OnetPathfinder

var grid_width: int
var grid_height: int
var grid: Array = [] 
var tilemap: TileMapLayer
var map_offset: Vector2i # The top-left of the used_rect minus 1 for padding

func _init(game_tilemap: TileMapLayer) -> void:
	self.tilemap = game_tilemap

## Rebuilds the internal logic grid based on the current TileMap state
func sync_grid_to_tilemap() -> void:
	var used_rect = tilemap.get_used_rect()
	
	# 1. Setup dimensions with 1-cell padding on all sides
	grid_width = used_rect.size.x + 2
	grid_height = used_rect.size.y + 2
	map_offset = used_rect.position - Vector2i(1, 1)
	
	# 2. Initialize with empty data
	grid = []
	for y in range(grid_height):
		var row = []
		for x in range(grid_width):
			row.append(TileIdentifiers.new())
		grid.append(row)
	
	# 3. Fill with data from TileMapFuncs
	for x in range(used_rect.size.x):
		for y in range(used_rect.size.y):
			var tile_coords = used_rect.position + Vector2i(x, y)
			# Store the dictionary in our logic grid at the padded position
			grid[y + 1][x + 1] = TileIdentifiers.from_tilemap(tile_coords, tilemap)
	
	print_grid()

## Helper to see if a cell is "passable" (empty)
func is_cell_empty(p: Vector2i) -> bool:
	var val = get_cell_value(p.x, p.y)
	return val == null or val.source_id == -1

## Compares two tiles to see if they match
func do_tiles_match(p1: Vector2i, p2: Vector2i) -> bool:
	var d1 = get_cell_value(p1.x, p1.y)
	var d2 = get_cell_value(p2.x, p2.y)
	if d1.source_id == -1 or d2.source_id == -1: return false
	
	return d1.source_id == d2.source_id and \
		   d1.atlas_coords == d2.atlas_coords and \
		   d1.alternative_id == d2.alternative_id

# --- PATHFINDING CORE ---

func is_straight_clear(p1: Vector2i, p2: Vector2i) -> bool:
	if p1.x != p2.x and p1.y != p2.y: return false
	
	if p1.x == p2.x: # Vertical
		for y in range(min(p1.y, p2.y) + 1, max(p1.y, p2.y)):
			if not is_cell_empty(Vector2i(p1.x, y)): return false
	else: # Horizontal
		for x in range(min(p1.x, p2.x) + 1, max(p1.x, p2.x)):
			if not is_cell_empty(Vector2i(x, p1.y)): return false
	return true

func check_1_bend(p1: Vector2i, p2: Vector2i) -> Array[Vector2i]:
	var corners = [Vector2i(p1.x, p2.y), Vector2i(p2.x, p1.y)]
	for c in corners:
		if is_cell_empty(c) and is_straight_clear(p1, c) and is_straight_clear(c, p2):
			return [p1, c, p2]
	return []

func check_2_bends(p1: Vector2i, p2: Vector2i) -> Array[Vector2i]:
	var directions = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
	for dir in directions:
		var current = p1 + dir
		while is_within_bounds(current) and is_cell_empty(current):
			var path_from_here = check_1_bend(current, p2)
			if path_from_here.size() > 0:
				var result: Array[Vector2i] = []
				result.append(p1)
				result.append_array(path_from_here)
				return result
			current += dir
	return []

# --- PUBLIC API ---

## Call this from your Game Controller. Uses TileMap coordinates.
func find_path_from_map_coords(m1: Vector2i, m2: Vector2i) -> Array[Vector2i]:
	sync_grid_to_tilemap()
	# Convert TileMap coords to our padded Grid coords
	var g1 = m1 - map_offset
	var g2 = m2 - map_offset
	
	if g1 == g2 or not do_tiles_match(g1, g2):
		return []
	
	var res: Array[Vector2i] = []
	if is_straight_clear(g1, g2): 
		res.assign([g1, g2])
	if res.is_empty(): res = check_1_bend(g1, g2)
	if res.is_empty(): res = check_2_bends(g1, g2)
	
	# Convert the path back to TileMap coordinates for drawing/deletion
	var map_path: Array[Vector2i] = []
	for p in res:
		map_path.append(p + map_offset)
	return map_path

# --- HELPERS ---

func get_cell_value(x, y):
	if is_within_bounds(Vector2i(x, y)):
		return grid[y][x]
	return {"source_id": -1} # Out of bounds sentinel

func is_within_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < grid_width and p.y >= 0 and p.y < grid_height

func print_grid() -> void:
	for i in grid.size():
		for j in grid[i].size():
			printraw(grid[i][j].atlas_coords)
		printraw("\n")
