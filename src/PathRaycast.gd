extends RayCast2D
class_name PathRaycast

const TILES_COLLISION_LAYER = 1
const RAYCAST_COLLISION_LAYER = 2

func _init() -> void:
	collide_with_bodies = false
	collide_with_areas = true
	enabled = true
	collision_mask = TILES_COLLISION_LAYER

func get_casting_global_pos() -> Vector2:
	return global_position + cast_to

func get_length() -> float:
	return global_position.distance_to(get_casting_global_pos())

func as_line(config: = {}) -> Line2D:
	var line = create_line(config)
	line.add_point(global_position)
	line.add_point(get_casting_global_pos())
	return line

static func create_line(config: = {}) -> Line2D:
	var line = Line2D.new()
	line.default_color = config.get("color", Color.white)
	line.width = config.get("width", 2.0)
	return line
