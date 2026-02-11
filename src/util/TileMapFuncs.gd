class_name TileMapFuncs

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
