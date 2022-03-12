tool
extends AcceptDialog

signal play_again

func _enter_tree() -> void:
	self.get_ok().text = "Play Again"

func _ready() -> void:
	get_close_button().disabled = true
	get_close_button().hide()
	connect("confirmed", self, "_on_confirm")
	
func display_results(results: Dictionary) -> void:
	if not Engine.editor_hint:
		dialog_text = ""
		for result in results.keys():
			dialog_text += str(result).capitalize() + ": " + str(results[result]) + "\n"
		popup()

func _on_confirm() -> void:
	emit_signal("play_again")
