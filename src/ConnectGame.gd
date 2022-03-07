extends Node2D

onready var tilemap = $Navigation2D/Tiles

export var level: int = 1
export var time_limit: = 0.0 setget set_time_limit

onready var timer: Timer = $Timer

var moves_taken: int = 0
var total_moves_taken: int = 0

func _ready() -> void:
	tilemap.connect("pair_cleared", self, "_on_pair_cleared")
# warning-ignore:return_value_discarded
	timer.connect("timeout", self, "_on_timeout")
	
func start_new_game() -> void:
	timer.stop()
	moves_taken = 0
	total_moves_taken = 0
	tilemap.start_new_game()
	
func set_time_limit(val: float) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	time_limit = val
	timer.wait_time = val

func _on_pair_cleared(_pair) -> void:
	moves_taken += 1
	total_moves_taken += 1
	if moves_taken == 1:
		timer.start(time_limit)

func _on_level_cleared() -> void:
	self.level += 1
	moves_taken = 0

func _on_Restart_pressed() -> void:
	start_new_game()

func _on_timeout() -> void:
	var results: Dictionary = {
		"level": level,
		"tiles_cleared": total_moves_taken * 2
	}
	$UI/GameOverDialog.display_results(results)

func _on_GameOverDialog_confirmed() -> void:
	start_new_game()
