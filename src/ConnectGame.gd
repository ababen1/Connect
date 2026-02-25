extends Node2D
class_name ConnectGame

signal game_over(stats)
signal level_completed(level_num)
signal time_limit_changed(new_time)

enum STATE {
	SELECT_DIFFICULTY,
	PLAYING,
	GAME_OVER,
}

@export var debug_mode: = false
@export var current_level: int = 1: set = set_current_level
@export var time_limit: = 210.0: set = set_time_limit


@onready var game_grid: ConnectGameGrid = %GameGrid
@onready var timer: Timer = $Timer

var moves_taken: int = 0
var total_moves_taken: int = 0
var current_difficulty: DifficultyData
var current_state: = STATE.SELECT_DIFFICULTY : set = set_current_state

func _ready() -> void:
	if not OS.is_debug_build():
		debug_mode = false
	timer.timeout.connect(_on_timeout)
	set_current_state(STATE.SELECT_DIFFICULTY)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		$UI/Pause.toggle()

func set_current_state(val: STATE) -> void:
	current_state = val
	%HeaderBar.visible =  current_state == STATE.PLAYING
	%SubViewportContainer.visible = current_state in [STATE.PLAYING, STATE.GAME_OVER]
	%NewGameDialog.visible = current_state == STATE.SELECT_DIFFICULTY
	
	
func start_new_game(difficulty: DifficultyData) -> void:
	current_difficulty = difficulty
	timer.stop()
	moves_taken = 0
	total_moves_taken = 0
	set_time_limit(difficulty.time_limit)
	set_current_state(STATE.PLAYING)
	game_grid.start_new_game(difficulty.board_size)
	await get_tree().process_frame
	check_board()

func set_current_level(val: int) -> void:
	current_level = val
	game_grid.board_size += Vector2i.ONE
	
func set_time_limit(val: float) -> void:
	if not is_inside_tree():
		await self.ready
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
	var confirmation = ConfirmationDialog.new()
	confirmation.dialog_text = "Start a new game?"
	confirmation.position = get_viewport_rect().get_center()
	var rect_size = Vector2(300,150)
	var rect = Rect2(get_viewport_rect().get_center() - rect_size / 2, rect_size)
	add_child(confirmation)
	confirmation.popup(rect)
	
	confirmation.canceled.connect(func(): confirmation.queue_free())
	confirmation.confirmed.connect(func(): set_current_state(STATE.SELECT_DIFFICULTY))

func _on_timeout() -> void:
	var results: Dictionary = {
		"level": current_level,
		"tiles_cleared": total_moves_taken * 2
	}
	emit_signal("game_over", results)

func _on_UI_next_level() -> void:
	self.current_level += 1
	moves_taken = 0


func check_board() -> void:
	if game_grid.check_win():
		level_completed.emit(current_level)
		timer.stop()

func _on_Hint_pressed() -> void:
	game_grid.display_hint()

func _on_new_game_dialog_difficulty_selected(difficulty: DifficultyData) -> void:
	start_new_game(difficulty)
