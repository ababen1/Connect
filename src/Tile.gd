extends Area2D

onready var collision_shape = $CollisionShape2D

func setup(tile_size: Vector2, world_position: Vector2) -> void:
	collision_shape.shape.extents = tile_size / 2
	global_position = world_position
	

	
