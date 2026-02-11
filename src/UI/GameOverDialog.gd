#@tool
extends AcceptDialog

signal play_again

func _enter_tree() -> void:
	self.get_ok_button().text = "Play Again"

func _ready() -> void:
	if not owner.debug_mode:
		add_theme_icon_override("close", Texture2D.new())
# warning-ignore:return_value_discarded
	connect("confirmed", Callable(self, "_on_confirm"))
	
func display_results(results: Dictionary) -> void:
	if not Engine.is_editor_hint():
		dialog_text = ""
		for result in results.keys():
			dialog_text += str(result).capitalize() + ": " + str(results[result]) + "\n"
		popup()

func _on_confirm() -> void:
	emit_signal("play_again")
