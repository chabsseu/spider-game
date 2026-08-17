extends Label

func _process(delta: float) -> void:
	text = Daynightcycle.get_time_string()