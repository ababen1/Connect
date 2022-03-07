extends Label

export var timer_node: NodePath setget set_timer_node

var _timer: Timer setget ,get_timer

func _process(_delta: float) -> void:
	if _timer and not _timer.is_stopped():
		set_time_left(_timer.time_left)

func set_time_left(time_left: float) -> void:
	text = (
		"%02d" % (time_left / 60)) + ":" +(
		"%02d" % (int(time_left) % 60))

func set_timer_node(val: NodePath) -> void:
	if not is_inside_tree():
		yield(self, "ready")
	timer_node = val
	_timer = get_node_or_null(val) as Timer
	if _timer:
		set_time_left(_timer.wait_time)
	
func get_timer() -> Timer:
	return get_node_or_null(timer_node) as Timer
		
func _on_Restart_pressed() -> void:
	set_time_left(_timer.wait_time)
