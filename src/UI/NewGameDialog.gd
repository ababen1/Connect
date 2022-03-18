extends WindowDialog

signal difficulty_selected(difficulty)

onready var difficulty_buttons = $VBox/DifficultyButtons

func _ready() -> void:
	for child in difficulty_buttons.get_children():
		if child is DifficultyButton:
			child.connect("pressed", self, "_on_difficulty_btn_pressed", [child])
			
func _on_difficulty_btn_pressed(btn: DifficultyButton) -> void:
	emit_signal("difficulty_selected", btn.data)
	queue_free()
