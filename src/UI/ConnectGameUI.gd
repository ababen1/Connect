extends CanvasLayer

const NEW_GAME_POPUP = preload("res://src/UI/NewGameDialog.tscn")

signal new_game(difficulty)
signal next_level

@onready var debug_labels = $DebugLabels

func _ready() -> void:
	debug_labels.visible = get_parent().debug_mode

func start_new_game():
	var new_game_dialog = NEW_GAME_POPUP.instantiate()
	add_child(new_game_dialog)
	new_game_dialog.popup()
	var difficulty: DifficultyData = await new_game_dialog.difficulty_selected
	emit_signal("new_game", difficulty)
