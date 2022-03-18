extends Area2D

onready var collision_shape = $CollisionShape2D
onready var audio_player = $SFX

func setup(tile_size: Vector2, world_position: Vector2) -> void:
	collision_shape.shape.extents = tile_size / 2
	global_position = world_position
	
func _input_event(_viewport: Object, event: InputEvent, _shape_idx: int) -> void:
	if event.is_action_pressed("click"):
		audio_player.play()
