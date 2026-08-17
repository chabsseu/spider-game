extends Node


signal night_started
signal day_started
signal hour_changed(hour: int)

@export var full_day_seconds: float = 600.0 ## real seconds for one full 24h cycle (2.5 min)
@export var canvas_modulate_path: NodePath
@export var night_start_hour: float = 19.0   ## 7 PM
@export var night_end_hour: float = 5.0      ## 5 AM
@export var paused: bool = false

## Colors for each key point in the cycle. Feel free to tune these
## in the Inspector once you see how they look in your game.
@export var color_noon: Color = Color(1.0, 1.0, 1.0)
@export var color_dusk: Color = Color(0.85, 0.55, 0.45)
@export var color_night: Color = Color(0.18, 0.2, 0.4)
@export var color_dawn: Color = Color(0.75, 0.6, 0.55)

var time_of_day: float = 19.0 ## 0-24, starts at 8 AM
var is_night: bool = false

@onready var canvas_modulate: CanvasModulate = get_node_or_null(canvas_modulate_path)

var _seconds_per_hour: float

func _ready() -> void:
	_seconds_per_hour = full_day_seconds / 24.0
	_update_night_state(true)
	_update_color()

func _process(delta: float) -> void:
	if paused:
		return

	var previous_hour := int(time_of_day)
	time_of_day += delta / _seconds_per_hour
	if time_of_day >= 24.0:
		time_of_day -= 24.0

	if int(time_of_day) != previous_hour:
		hour_changed.emit(int(time_of_day))

	_update_night_state(false)
	_update_color()

func set_paused(value: bool) -> void:
	paused = value

func _update_night_state(force_no_signal: bool) -> void:
	var was_night := is_night
	# Handles wraparound (e.g. night 19:00 -> 05:00 crosses midnight).
	if night_start_hour > night_end_hour:
		is_night = time_of_day >= night_start_hour or time_of_day < night_end_hour
	else:
		is_night = time_of_day >= night_start_hour and time_of_day < night_end_hour

	if force_no_signal:
		return
	if is_night and not was_night:
		night_started.emit()
	elif not is_night and was_night:
		day_started.emit()

func _update_color() -> void:
	if not canvas_modulate:
		return
	canvas_modulate.color = _get_color_for_time(time_of_day)

## Returns the blended lighting color for any given hour (0-24).
## Cycle: dawn -> noon -> dusk -> night -> dawn.
func _get_color_for_time(hour: float) -> Color:
	# Key hours: 5=dawn start, 8=full day, 18=dusk start, 20=full night, 5=dawn again
	if hour >= 5.0 and hour < 8.0:
		return color_dawn.lerp(color_noon, (hour - 5.0) / 3.0)
	elif hour >= 8.0 and hour < 18.0:
		return color_noon
	elif hour >= 18.0 and hour < 20.0:
		return color_noon.lerp(color_dusk, (hour - 18.0) / 2.0) if hour < 19.0 \
			else color_dusk.lerp(color_night, (hour - 19.0) / 1.0)
	elif hour >= 20.0 or hour < 3.0:
		return color_night
	else: # 3.0 - 5.0, night fading into dawn
		return color_night.lerp(color_dawn, (hour - 3.0) / 2.0)

## Utility for UI: formats current time as "HH:MM" (24-hour).
func get_time_string() -> String:
	var h := int(time_of_day)
	var m := int((time_of_day - h) * 60.0)
	return "%02d:%02d" % [h, m]