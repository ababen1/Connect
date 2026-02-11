extends Node
class_name TilesSetup

@onready var tilemap: TileMap = get_parent()
@onready var tileset: TileSet = tilemap.tile_set

func _ready() -> void:
	pass
	
func get_tiles_of_category(category: String) -> Array[TileData]:
	var tiles: Array[TileData] = []
	tileset.get_custom_data_layer_by_name("category")
	
func fill_map_with_food():
	var ts: TileSet = tile_set
	var current_x = 0 # To place them in a line for this example
	
	# 1. Loop through all Sources (Atlases) in the TileSet
	for i in ts.get_source_count():
		var source_id = ts.get_source_id(i)
		var source: TileSetSource = ts.get_source(source_id)
		
		if source is TileSetAtlasSource:
			# 2. Loop through every individual tile in this Atlas
			for j in source.get_tiles_count():
				var atlas_coords = source.get_tile_id(j)
				
				# 3. Get the data for this specific tile
				var tile_data: TileData = source.get_tile_data(atlas_coords, 0)
				
				# 4. Check if it matches your "food" category
				if tile_data.get_custom_data("category") == "food":
					# 5. Place the tile on the map
					set_cell(Vector2i(current_x, 0), source_id, atlas_coords)
					current_x += 1
	
