extends Node
class_name BattleController

## Runs an auto-battle between two Spider resources. Attach this to a
## Node in your battle scene, assign spider_a / spider_b (or call
## start_battle with two Spider instances), and connect to the
## signals below to drive your UI/animations.

signal battle_started
signal attack_landed(attacker: Spider, defender: Spider, result: Dictionary)
signal shield_broke(spider: Spider)
signal battle_ended(winner: Spider, loser: Spider)

@export var spider_a: Spider
@export var spider_b: Spider
@export var tick_interval: float = 0.12 ## Seconds between gauge ticks. Lower = faster fight.
@export var autostart: bool = false

var _running: bool = false
var _tick_timer: Timer

func _ready() -> void:
	_tick_timer = Timer.new()
	_tick_timer.wait_time = tick_interval
	_tick_timer.one_shot = false
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)

	if autostart and spider_a and spider_b:
		start_battle(spider_a, spider_b)

func start_battle(a: Spider, b: Spider) -> void:
	spider_a = a
	spider_b = b
	spider_a.reset_for_battle()
	spider_b.reset_for_battle()
	_running = true
	_tick_timer.start()
	battle_started.emit()

func stop_battle() -> void:
	_running = false
	_tick_timer.stop()

func _on_tick() -> void:
	if not _running:
		return

	# Both spiders' gauges advance every tick; either or both may fire.
	if spider_a.tick_gauge():
		_resolve_attack(spider_a, spider_b)
		if _check_for_winner():
			return

	if spider_b.tick_gauge():
		_resolve_attack(spider_b, spider_a)
		if _check_for_winner():
			return

func _resolve_attack(attacker: Spider, defender: Spider) -> void:
	var roll := attacker.roll_attack_damage()
	var result := defender.take_damage(roll["damage"])
	result["is_crit"] = roll["is_crit"]
	result["raw_damage"] = roll["damage"]

	attack_landed.emit(attacker, defender, result)

	if result["shield_broke"]:
		shield_broke.emit(defender)

func _check_for_winner() -> bool:
	if spider_b.is_defeated():
		stop_battle()
		battle_ended.emit(spider_a, spider_b)
		return true
	if spider_a.is_defeated():
		stop_battle()
		battle_ended.emit(spider_b, spider_a)
		return true
	return false
