tool
extends AcceptDialog

signal next_level

func _enter_tree() -> void:
	get_close_button().disabled = true
	get_close_button().hide()
	get_ok().text = "Next level"

func _ready() -> void:
	connect("confirmed", self, "_on_confirm")

func display(level_num: int) -> void:
	dialog_text = "Level {lvl} Completed!".format({"lvl": level_num as String})
	popup()

func _on_confirm() -> void:
	emit_signal("next_level")
