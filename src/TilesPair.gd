extends Node
class_name TilesPair

var tile1_cords: Vector2
var tile2_cords: Vector2

func _init(tile1: Vector2, tile2: Vector2) -> void:
	self.tile1_cords = tile1
	self.tile2_cords = tile2

func as_array() -> PoolVector2Array:
	return PoolVector2Array([tile1_cords, tile2_cords])
