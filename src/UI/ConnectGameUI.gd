extends CanvasLayer

const NEW_GAME_POPUP = preload("res://src/UI/NewGameDialog.tscn")

signal new_game(difficulty)
signal next_level

@onready var debug_labels = $DebugLabels

func _ready() -> void:
	debug_labels.visible = get_parent().debug_mode
