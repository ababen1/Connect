extends VBoxContainer

func _ready() -> void:
	visible = OS.is_debug_build()

func set_label(id: String, text: String) -> void:
	var label = _find_label(id)
	if not label:
		label = _new_label(id, text)
		add_child(label)
	_update_label_text(label, text)

func _update_label_text(label: Label, text: String) -> void:
	label.text = "{id}: {value}".format({\
		"id": label.get_meta("id"), 
		"value": text})

func _new_label(id: String, text: String) -> Label:
	var label = Label.new()
	label.text = text
	label.set_meta("id", id)
	return label
	
func _find_label(id: String) -> Label:
	for child in get_children():
		if child.get_meta("id") == id:
			return child
	return null
