extends Node2D

@onready var opponent_sprite: TextureRect = $OpponentArea/Sprite
@onready var opponent_placeholder: ColorRect = $OpponentArea/Placeholder
@onready var opponent_name_label: Label = $OpponentArea/NameLabel
@onready var opponent_health_bar: ProgressBar = $OpponentArea/HealthBar
@onready var opponent_shield_bar: ProgressBar = $OpponentArea/ShieldBar

@onready var player_sprite: TextureRect = $PlayerArea/Sprite
@onready var player_placeholder: ColorRect = $PlayerArea/Placeholder
@onready var player_name_label: Label = $PlayerArea/NameLabel
@onready var player_health_bar: ProgressBar = $PlayerArea/HealthBar
@onready var player_shield_bar: ProgressBar = $PlayerArea/ShieldBar

@onready var result_label: Label = $ResultLabel
@onready var continue_button: Button = $ContinueButton
@onready var battle_controller: BattleController = $BattleController
@onready var broadcast_label: Label = $BroadcastLabel

var _bet_reward: int = 0
var _player_spider_name: String = ""

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _shake_rng := RandomNumberGenerator.new()
var _base_position: Vector2

const SHAKE_NORMAL_STRENGTH := 4.0
const SHAKE_NORMAL_DURATION := 0.15
const SHAKE_CRIT_STRENGTH := 18.0
const SHAKE_CRIT_DURATION := 0.4
const MAX_BROADCAST_LINES: int = 5

func _ready() -> void:
	continue_button.hide()
	result_label.text = ""
	broadcast_label.text = ""
	_base_position = position
	_shake_rng.randomize()
	continue_button.pressed.connect(_on_continue_pressed)
	battle_controller.attack_landed.connect(_on_attack_landed)
	battle_controller.battle_ended.connect(_on_battle_ended)

	_bet_reward = BattleContext.bet_reward
	var caught_spider: CaughtSpider = BattleContext.player_spider_data
	var opponent_species: SpiderSpecies = BattleContext.opponent_species

	var player_spider := Spider.from_species(caught_spider.species)
	var opponent_spider := Spider.from_species(opponent_species)
	_player_spider_name = player_spider.spider_name

	player_name_label.text = player_spider.spider_name
	opponent_name_label.text = opponent_spider.spider_name

	_set_display_sprite(player_sprite, player_placeholder, caught_spider.species.icon)
	_set_display_sprite(opponent_sprite, opponent_placeholder, opponent_species.icon)

	battle_controller.start_battle(player_spider, opponent_spider)
	_update_bars()

func _process(delta: float) -> void:
	if _shake_duration > 0.0:
		_shake_duration -= delta
		position = _base_position + Vector2(
			_shake_rng.randf_range(-_shake_strength, _shake_strength),
			_shake_rng.randf_range(-_shake_strength, _shake_strength)
		)
		if _shake_duration <= 0.0:
			position = _base_position

func shake(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = duration

func _set_display_sprite(sprite_rect: TextureRect, placeholder: ColorRect, icon: Texture2D) -> void:
	if icon:
		sprite_rect.texture = icon
		sprite_rect.show()
		placeholder.hide()
	else:
		sprite_rect.hide()
		placeholder.show()

func _on_attack_landed(attacker: Spider, defender: Spider, result: Dictionary) -> void:
	_update_bars()

	if result["is_crit"]:
		shake(SHAKE_CRIT_STRENGTH, SHAKE_CRIT_DURATION)
	else:
		shake(SHAKE_NORMAL_STRENGTH, SHAKE_NORMAL_DURATION)

	_show_broadcast(attacker, defender, result)

func _show_broadcast(attacker: Spider, defender: Spider, result: Dictionary) -> void:
	var dmg: int = result["health_damage"]
	var absorbed: int = result["absorbed"]
	var line: String = ""

	if result["is_crit"]:
		if absorbed > 0 and dmg == 0:
			line = "CRITICAL HIT! %s's shield absorbed it!" % defender.spider_name
		else:
			line = "CRITICAL HIT! %s dealt %d to %s!" % [attacker.spider_name, dmg, defender.spider_name]
	else:
		if absorbed > 0 and dmg == 0:
			line = "%s's shield blocked the hit!" % defender.spider_name
		else:
			line = "%s hit %s for %d!" % [attacker.spider_name, defender.spider_name, dmg]

	if result["shield_broke"]:
		line += " Shield broke!"

	if broadcast_label.text == "":
		broadcast_label.text = line
	else:
		broadcast_label.text += "\n" + line

	_trim_broadcast_log()

func _trim_broadcast_log() -> void:
	var lines: Array = broadcast_label.text.split("\n")
	if lines.size() > MAX_BROADCAST_LINES:
		lines = lines.slice(lines.size() - MAX_BROADCAST_LINES, lines.size())
		broadcast_label.text = "\n".join(lines)

func _update_bars() -> void:
	var a: Spider = battle_controller.spider_a
	var b: Spider = battle_controller.spider_b
	if not a or not b:
		return

	player_health_bar.max_value = a.max_health
	player_health_bar.value = a.current_health
	player_shield_bar.max_value = max(1, a.max_shield)
	player_shield_bar.value = a.current_shield

	opponent_health_bar.max_value = b.max_health
	opponent_health_bar.value = b.current_health
	opponent_shield_bar.max_value = max(1, b.max_shield)
	opponent_shield_bar.value = b.current_shield

func _on_battle_ended(winner: Spider, loser: Spider) -> void:
	_update_bars()
	var player_won := winner.spider_name == _player_spider_name
	if player_won:
		Economy.add_money(_bet_reward)
		result_label.text = "You won! +₱%d" % _bet_reward
		result_label.modulate = Color(0.435, 0.812, 0.592)
		
		# 1. Marks defeated challenger inside BattleContext's primary array
		BattleContext.mark_current_challenger_defeated()
		
		# 2. Syncs with world dictionary safely
		if not BattleContext.persistent_world_data.has("defeated_opponents"):
			BattleContext.persistent_world_data["defeated_opponents"] = []
			
		if BattleContext.persistent_world_data.has("last_opponent_id"):
			var npc_id: String = BattleContext.persistent_world_data["last_opponent_id"]
			if not BattleContext.persistent_world_data["defeated_opponents"].has(npc_id):
				BattleContext.persistent_world_data["defeated_opponents"].append(npc_id)
	else:
		result_label.text = "You lost..."
		result_label.modulate = Color(0.847, 0.353, 0.188)
		
	continue_button.show()

func _on_continue_pressed() -> void:
	BattleContext.return_to_world()