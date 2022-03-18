extends AudioStreamPlayer

const ERROR_SOUND = preload("res://assets/sfx/Error Sound 2.wav")
const POP_SOUND = preload("res://assets/sfx/Pop sound 9.wav")
const WIN_SOUND = preload("res://assets/sfx/Win sound 11.wav")
const LOSS_SOUND = preload("res://assets/sfx/Lost sound 1.wav")

func _on_Tiles_pair_cleared(pair) -> void:
	stream = POP_SOUND
	play()


func _on_Tiles_misplay() -> void:
	stream = ERROR_SOUND
	play()


func _on_ConnectGame_level_completed(_level_num) -> void:
	if playing:
		stop()
		yield(get_tree(), "idle_frame")
	stream = WIN_SOUND
	play()


func _on_ConnectGame_game_over(stats) -> void:
	stream = LOSS_SOUND
	play()
