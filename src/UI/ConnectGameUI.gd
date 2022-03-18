extends CanvasLayer

const NEW_GAME_POPUP = preload("res://src/UI/NewGameDialog.tscn")

signal new_game(difficulty)
signal next_level

onready var game_over_dialog = $GameOverDialog
onready var level_completed_dialog = $LevelCompleteDialog
onready var debug_labels = $DebugLabels

func _ready() -> void:
	debug_labels.visible = get_parent().debug_mode

func _on_ConnectGame_game_over(stats) -> void:
	game_over_dialog.display_results(stats)
	yield(game_over_dialog, "play_again")
	start_new_game()

func _on_ConnectGame_level_completed(level_num) -> void:
	level_completed_dialog.display(level_num)
	yield(level_completed_dialog, "next_level")
	emit_signal("next_level")

func start_new_game():
	var new_game_dialog = NEW_GAME_POPUP.instance()
	add_child(new_game_dialog)
	new_game_dialog.popup()
	var difficulty: DifficultyData = yield(new_game_dialog, "difficulty_selected")
	emit_signal("new_game", difficulty)
