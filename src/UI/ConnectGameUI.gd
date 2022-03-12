extends CanvasLayer

signal new_game
signal next_level

onready var game_over_dialog = $GameOverDialog
onready var level_completed_dialog = $LevelCompleteDialog
onready var debug_labels = $DebugLabels

func _ready() -> void:
	debug_labels.visible = get_parent().debug_mode

func _on_ConnectGame_game_over(stats) -> void:
	game_over_dialog.display_results(stats)
	yield(game_over_dialog, "play_again")
	emit_signal("new_game")

func _on_ConnectGame_level_completed(level_num) -> void:
	level_completed_dialog.display(level_num)
	
