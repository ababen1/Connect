extends Resource
class_name TileIdentifiers

@export var source_id: = -1
@export var atlas_coords: = -Vector2i.ONE
@export var alternative_id: int = -1

func _init(src: int = -1, atlas: = -Vector2.ONE, alt: = -1) -> void:
	self.source_id = src
	self.atlas_coords = atlas
	self.alternative_id = alt

func to_dict() -> Dictionary:
	return {
		"source_id": source_id,
		"atlas_coords": atlas_coords,
		"alternative_id": alternative_id
	}

static func from_tilemap(cell: Vector2i, tilemap: TileMapLayer) -> TileIdentifiers:
	return TileIdentifiers.new(
		tilemap.get_cell_source_id(cell),
		tilemap.get_cell_atlas_coords(cell),
		tilemap.get_cell_alternative_tile(cell)
	)

	
static func from_dict(dict: Dictionary) -> TileIdentifiers:
	return TileIdentifiers.new(
		dict.get("source_id", -1),
		dict.get("atlas_coords", -Vector2.ONE),
		dict.get("alternative_tile", -1),
	)
