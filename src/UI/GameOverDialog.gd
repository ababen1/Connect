tool
extends AcceptDialog

func _enter_tree() -> void:
	self.get_ok().text = "Play Again"

func display_results(results: Dictionary) -> void:
	if not Engine.editor_hint:
		dialog_text = ""
		for result in results.keys():
			dialog_text += str(result).capitalize() + ": " + str(results[result]) + "\n"
		popup()
