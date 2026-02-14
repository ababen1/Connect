class_name TileMapFuncs

## Serializes a cell
static func get_cell_id(tilemap: TileMapLayer, cell: Vector2i) -> String:
	return var_to_str(get_cell_identifiers(tilemap, cell))

## Get identifiers for a given cell
static func get_cell_identifiers(tilemap: TileMapLayer, cell: Vector2i) -> Dictionary:
	var source_id = tilemap.get_cell_source_id(cell)
	var atlas_coords = tilemap.get_cell_atlas_coords(cell)
	var alternative_id = tilemap.get_cell_alternative_tile(cell)
	return {
		"source_id": source_id,
		"atlas_coords": atlas_coords, 
		"alternative_id": alternative_id	
	}
	
## Check if a given cell is empty	
static func is_empty_cell(tilemap: TileMapLayer, cell: Vector2i) -> bool:
	var identifiers: = get_cell_identifiers(tilemap, cell)
	return identifiers.source_id != -1 and identifiers.atlas_coords != -Vector2i.ONE

## Checks if two tiles are identitcal 
static func are_tiles_same(tilemap: TileMapLayer, coords1: Vector2i, coords2: Vector2i) -> bool:
	# Get the source ID and atlas coordinates for the first tile
	var source_id1 = tilemap.get_cell_source_id(coords1)
	var atlas_coords1 = tilemap.get_cell_atlas_coords(coords1)

	# Get the source ID and atlas coordinates for the second tile
	var source_id2 = tilemap.get_cell_source_id(coords2)
	var atlas_coords2 = tilemap.get_cell_atlas_coords(coords2)

	# Check if both sets of data match. A source ID of -1 indicates an empty cell.
	if source_id1 != -1 and source_id2 != -1:
		return source_id1 == source_id2 and atlas_coords1 == atlas_coords2

	# If one or both are empty, they are only "the same" if both are empty (-1)
	return source_id1 == source_id2

static func get_possible_tiles(tile_set: TileSet) -> Array[TileData]:
	var tiles: Array[TileData] = []
	for source_index: int in tile_set.get_source_count():
		tiles.append_array(get_all_tiles_in_atlas(tile_set, tile_set.get_source_id(source_index)))
	return tiles

static func get_all_tiles_in_atlas(tile_set: TileSet, atlas_id: int) -> Array[TileData]:
	var atlas: TileSetAtlasSource = tile_set.get_source(atlas_id)
	var atlas_size = atlas.get_atlas_grid_size()
	var tiles: Array[TileData] = []
	for row: int in atlas_size.y:
		for col: int in atlas_size.x:
			var current_cell = Vector2i(col, row)
			if atlas.has_tile(current_cell):
				var current_tile = atlas.get_tile_data(current_cell, 0)
				current_tile.set_meta("source_id", atlas_id)
				current_tile.set_meta("atlas_coords", current_cell)
				tiles.append(current_tile)
	return tiles
