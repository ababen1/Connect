extends Node2D

signal game_over(stats)
signal level_completed(level_num)
signal time_limit_changed(new_time)

export var debug_mode: = false
export var current_level: int = 1
export var time_limit: = 210.0 setget set_time_limit

onready var timer: Timer = $Timer
onready var grid = $Tiles
onready var ui = $UI

var moves_taken: int = 0
var total_moves_taken: int = 0

func _ready() -> void:
	grid.connect("pair_cleared", self, "_on_pair_cleared")
# warning-ignore:return_value_discarded
	timer.connect("timeout", self, "_on_timeout")
	$Tiles/RaycastsPathfinder.visible = debug_mode
	
func start_new_game() -> void:
	timer.stop()
	moves_taken = 0
	total_moves_taken = 0
	grid.start_new_game()
	
func set_time_limit(val: float) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	time_limit = val
	timer.wait_time = val
	emit_signal("time_limit_changed", val)

func _on_pair_cleared(_pair) -> void:
	moves_taken += 1
	total_moves_taken += 1
	if moves_taken == 1:
		timer.start(time_limit)
	elif grid.check_win():
		emit_signal("level_completed", current_level)

func _on_Restart_pressed() -> void:
	start_new_game()

func _on_timeout() -> void:
	var results: Dictionary = {
		"level": current_level,
		"tiles_cleared": total_moves_taken * 2
	}
	emit_signal("game_over", results)

func _on_UI_new_game() -> void:
	start_new_game()

func _on_UI_next_level() -> void:
	self.current_level += 1
	moves_taken = 0
	start_new_game()


func _on_Hint_pressed() -> void:
	grid.display_hint()
