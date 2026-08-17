extends Control
class_name CatchMinigame

## Spider catching minigame: a needle sweeps back and forth across a bar.
## Player presses a button/key when the needle is inside the green zone.
## 3 successful hits = caught. The zone shrinks and the needle speeds up
## after each hit. One miss is allowed total — a second miss ends the attempt.
##
## Usage: instance this scene, connect to catch_succeeded / catch_failed,
## call start_attempt(difficulty) to begin. difficulty (0.0-1.0) should be
## derived from the spider's stats — higher difficulty = thinner starting
## zone and faster starting needle speed.

signal catch_succeeded
signal catch_failed
signal hit_missed

@export var hits_required: int = 3
@export var base_zone_width_pct: float = 28.0
@export var zone_shrink_per_hit_pct: float = 7.0
@export var min_zone_width_pct: float = 10.0
@export var base_needle_speed: float = 55.0 ## % of bar per second
@export var speed_increase_per_hit: float = 30.0
@export var max_retries: int = 1
@export var input_action: String = "ui_accept" ## change to your catch button

@onready var bar_track: Control = $BarTrack
@onready var zone_rect: ColorRect = $BarTrack/Zone
@onready var needle_rect: ColorRect = $BarTrack/Needle
@onready var result_label: Label = $ResultLabel

var _hit_count: int = 0
var _miss_count: int = 0
var _running: bool = false
var _needle_pos: float = 0.0  # 0-100
var _needle_dir: int = 1
var _needle_speed: float = 0.0
var _zone_width_pct: float = 0.0
var _zone_center_pct: float = 0.0
var _difficulty: float = 0.0

func start_attempt(difficulty: float = 0.0) -> void:
	_difficulty = clamp(difficulty, 0.0, 1.0)
	_hit_count = 0
	_miss_count = 0
	_needle_speed = base_needle_speed + (_difficulty * 25.0)
	_needle_pos = randf() * 100.0
	_needle_dir = 1 if randf() < 0.5 else -1
	_randomize_zone()
	_running = true
	result_label.text = ""
	show()

func _randomize_zone() -> void:
	var shrink := zone_shrink_per_hit_pct * _hit_count
	var difficulty_shrink := _difficulty * 6.0
	_zone_width_pct = max(min_zone_width_pct, base_zone_width_pct - shrink - difficulty_shrink)
	# Keep the zone fully on the bar (don't let it clip past 0% or 100%).
	var half := _zone_width_pct / 2.0
	_zone_center_pct = randf_range(half, 100.0 - half)
	_update_zone_visual()

func _update_zone_visual() -> void:
	var half := _zone_width_pct / 2.0
	zone_rect.position.x = (max(0.0, _zone_center_pct - half) / 100.0) * bar_track.size.x
	zone_rect.size.x = (_zone_width_pct / 100.0) * bar_track.size.x

func _process(delta: float) -> void:
	if not _running:
		return

	_needle_pos += _needle_dir * _needle_speed * delta
	if _needle_pos >= 100.0:
		_needle_pos = 100.0
		_needle_dir = -1
	elif _needle_pos <= 0.0:
		_needle_pos = 0.0
		_needle_dir = 1

	needle_rect.position.x = (_needle_pos / 100.0) * bar_track.size.x

	if Input.is_action_just_pressed(input_action):
		_evaluate_hit()

func _evaluate_hit() -> void:
	var half := _zone_width_pct / 2.0
	var in_zone := _needle_pos >= (_zone_center_pct - half) and _needle_pos <= (_zone_center_pct + half)

	if in_zone:
		_hit_count += 1
		_needle_speed += speed_increase_per_hit
		if _hit_count >= hits_required:
			_finish(true)
		else:
			_randomize_zone()
	else:
		_miss_count += 1
		hit_missed.emit()
		if _miss_count > max_retries:
			_finish(false)
		# else: allowed miss, keep going with current zone/speed.

func _finish(success: bool) -> void:
	_running = false
	if success:
		result_label.text = "Caught it! 🕷️"
		result_label.modulate = Color(0.435, 0.812, 0.592)
	else:
		result_label.text = "It got away..."
		result_label.modulate = Color(0.847, 0.353, 0.188)

	# Give the player a beat to read the result before hiding.
	await get_tree().create_timer(0.8).timeout

	if success:
		catch_succeeded.emit()
	else:
		catch_failed.emit()