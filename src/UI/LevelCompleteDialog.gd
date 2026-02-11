#@tool
extends AcceptDialog

signal next_level

func _enter_tree() -> void:
	add_theme_icon_override("close", Texture2D.new())
	get_ok_button().text = "Next level"

func _ready() -> void:
# warning-ignore:return_value_discarded
	connect("confirmed", Callable(self, "_on_confirm"))

func display(level_num: int) -> void:
	dialog_text = "Level {lvl} Completed!".format({"lvl": var_to_str(level_num)})
	popup()

func _on_confirm() -> void:
	emit_signal("next_level")
