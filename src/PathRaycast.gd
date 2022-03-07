extends RayCast2D
class_name PathRaycast

const TILES_COLLISION_LAYER = 1

func _init() -> void:
	collide_with_bodies = false
	collide_with_areas = true
	enabled = true
	collision_mask = TILES_COLLISION_LAYER
