extends Button
class_name DifficultyButton

export var data: Resource setget set_data

func set_data(val: DifficultyData) -> void:
	data = val
	text = data.name if val else ""
	
