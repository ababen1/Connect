extends Resource
class_name PairData

var cell1: Vector2i
var cell2: Vector2i
var tile_identifiers: TileIdentifiers

func _init(tile1: Vector2i, tile2: Vector2i, _tile_identifiers: TileIdentifiers = null) -> void:
	self.cell1 = tile1
	self.cell2 = tile2
	self.tile_identifiers = _tile_identifiers if _tile_identifiers else TileIdentifiers.new()

func as_array() -> PackedVector2Array:
	return PackedVector2Array([cell1, cell2])
