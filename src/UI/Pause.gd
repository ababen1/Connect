extends Control

func _enter_tree() -> void:
	visible = get_tree().paused

func toggle() -> void:
	get_tree().paused = !get_tree().paused
	visible = get_tree().paused


func _on_Button_pressed() -> void:
	toggle()
