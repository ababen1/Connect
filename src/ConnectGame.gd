extends Node2D

const NEW_GAME_POPUP = preload("res://src/UI/NewGameDialog.tscn")

signal game_over(stats)
signal level_completed(level_num)
signal time_limit_changed(new_time)

export var debug_mode: = false
export var current_level: int = 1 setget set_current_level
export var time_limit: = 210.0 setget set_time_limit

onready var timer: Timer = $Timer
onready var grid = $Tiles
onready var ui = $UI
onready var current_board_size = grid.board_size

var moves_taken: int = 0
var total_moves_taken: int = 0
var current_difficulty: DifficultyData

func _ready() -> void:
	if not OS.is_debug_build():
		debug_mode = false
	grid.connect("pair_cleared", self, "_on_pair_cleared")
# warning-ignore:return_value_discarded
	timer.connect("timeout", self, "_on_timeout")
	$Tiles/RaycastsPathfinder.visible = debug_mode
	ui.connect("new_game", self, "start_new_game")
	$UI/TimeLeft.set_time_left(self.time_limit)
	ui.start_new_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		$UI/Pause.toggle()
	
func start_new_game(difficulty: DifficultyData) -> void:
	current_difficulty = difficulty
	timer.stop()
	moves_taken = 0
	total_moves_taken = 0
	set_time_limit(difficulty.time_limit)
	current_board_size = difficulty.board_size
	grid.start_new_game(current_board_size)
	yield(get_tree(), "idle_frame")
	check_board()

func set_current_level(val: int) -> void:
	current_level = val
	current_board_size += Vector2.ONE
	
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
	check_board()

func _on_Restart_pressed() -> void:
	ui.start_new_game()

func _on_timeout() -> void:
	var results: Dictionary = {
		"level": current_level,
		"tiles_cleared": total_moves_taken * 2
	}
	emit_signal("game_over", results)

func _on_UI_next_level() -> void:
	self.current_level += 1
	moves_taken = 0
	grid.setup_board()

func check_board() -> void:
	if grid.check_win():
		emit_signal("level_completed", current_level)
		timer.stop()
	else:
		while not grid.has_possible_paths():
			grid.shuffle_board()

func _on_Hint_pressed() -> void:
	grid.display_hint()
