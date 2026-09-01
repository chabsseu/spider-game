extends Node2D

# Load your pixel font (Ensure the path matches your project structure)
const MINECRAFT_FONT := preload("res://Minecraft.ttf")

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

	player_spider.spider_name = caught_spider.get_display_name()
	_player_spider_name = player_spider.spider_name

	player_name_label.text = _player_spider_name
	opponent_name_label.text = opponent_spider.spider_name

	_set_display_sprite(player_sprite, player_placeholder, caught_spider.species.icon, true)
	_set_display_sprite(opponent_sprite, opponent_placeholder, opponent_species.icon, false)

	

	# Pre-assign spiders so UI bars display correctly behind the screen
	battle_controller.spider_a = player_spider
	battle_controller.spider_b = opponent_spider
	_update_bars()

	# Perfectly wait until TransitionUi finishes opening completely
	await TransitionUi.transition_finished

	# Start battle the exact frame the circle transition finishes expanding
	battle_controller.start_battle(player_spider, opponent_spider)

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

func _set_display_sprite(sprite_rect: TextureRect, placeholder: ColorRect, icon: Texture2D, flip_horizontal: bool = false) -> void:
	if icon:
		sprite_rect.texture = icon
		sprite_rect.flip_h = flip_horizontal
		sprite_rect.show()
		placeholder.hide()
	else:
		sprite_rect.hide()
		placeholder.show()

func _on_attack_landed(attacker: Spider, defender: Spider, result: Dictionary) -> void:
	_update_bars()

	# Object reference comparison fixes the duplicate name targeting bug
	var is_player_attacker := (attacker == battle_controller.spider_a)
	
	var atk_sprite := player_sprite if is_player_attacker else opponent_sprite
	var def_sprite := opponent_sprite if is_player_attacker else player_sprite
	var def_area: Control = $OpponentArea if is_player_attacker else $PlayerArea

	var is_crit: bool = result["is_crit"]
	var dmg: int = result["health_damage"]
	var absorbed: int = result["absorbed"]

	# 1. Screen Shake
	if is_crit:
		shake(SHAKE_CRIT_STRENGTH, SHAKE_CRIT_DURATION)
	else:
		shake(SHAKE_NORMAL_STRENGTH, SHAKE_NORMAL_DURATION)

	# 2. Visual Polish Animations
	_play_attack_animations(atk_sprite, def_sprite, is_crit)
	_spawn_damage_number(def_area, dmg if dmg > 0 else absorbed, is_crit, (absorbed > 0 and dmg == 0))

	# 3. Log Output
	_show_broadcast(attacker, defender, result)

func _play_attack_animations(attacker_sprite: TextureRect, defender_sprite: TextureRect, is_crit: bool) -> void:
	var tween := create_tween().set_parallel(true)
	
	# Determine forward direction relative to player/opponent placement
	var is_player := (attacker_sprite == player_sprite)
	var forward_dir := Vector2.RIGHT if is_player else Vector2.LEFT
	var lunge_distance := 40.0 if is_crit else 20.0
	
	# Attacker Lunge Forward & Snap Back
	var orig_pos: Vector2 = attacker_sprite.position
	tween.tween_property(attacker_sprite, "position", orig_pos + (forward_dir * lunge_distance), 0.08).set_trans(Tween.TRANS_QUAD)
	tween.chain().tween_property(attacker_sprite, "position", orig_pos, 0.12).set_trans(Tween.TRANS_QUAD)
	
	# Defender Flash Red on Impact
	defender_sprite.modulate = Color(2.5, 0.4, 0.4)
	tween.tween_property(defender_sprite, "modulate", Color.WHITE, 0.25)

func _spawn_damage_number(defender_area: Control, amount: int, is_crit: bool, shield_absorbed: bool) -> void:
	var label := Label.new()
	
	# Apply Minecraft Font
	label.add_theme_font_override("font", MINECRAFT_FONT)
	
	if shield_absorbed:
		label.text = "BLOCKED!"
		label.modulate = Color(0.4, 0.7, 1.0)
		label.add_theme_font_size_override("font_size", 14)
	elif is_crit:
		label.text = "%d CRIT!" % amount
		label.modulate = Color(1.0, 0.85, 0.2)
		label.add_theme_font_size_override("font_size", 64)
	else:
		label.text = "-%d" % amount
		label.modulate = Color(1.0, 0.35, 0.35)
		label.add_theme_font_size_override("font_size", 32)

	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = defender_area.global_position + Vector2(defender_area.size.x * 0.3, -10.0)
	
	add_child(label)
	
	# Set pivot after adding to tree for proper scaling origin
	label.pivot_offset = label.size / 2.0
	
	var float_distance := 50.0 if is_crit else 35.0
	var tween := create_tween().set_parallel(true)
	
	label.scale = Vector2(0.5, 0.5)
	var target_scale := Vector2(1.2, 1.2) if is_crit else Vector2(1.0, 1.0)
	tween.tween_property(label, "scale", target_scale, 0.12).set_ease(Tween.EASE_OUT)
	
	tween.tween_property(label, "global_position:y", label.global_position.y - float_distance, 0.45).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "modulate:a", 0.0, 0.45).set_ease(Tween.EASE_IN)
	
	await tween.finished
	label.queue_free()

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

	# Set maximum values directly
	player_health_bar.max_value = a.max_health
	player_shield_bar.max_value = max(1, a.max_shield)

	opponent_health_bar.max_value = b.max_health
	opponent_shield_bar.max_value = max(1, b.max_shield)

	# Animate value transitions smoothly using a parallel Tween
	var tween := create_tween().set_parallel(true)
	var duration := 0.25 # Seconds to reach new value

	tween.tween_property(player_health_bar, "value", a.current_health, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(player_shield_bar, "value", a.current_shield, duration).set_ease(Tween.EASE_OUT)

	tween.tween_property(opponent_health_bar, "value", b.current_health, duration).set_ease(Tween.EASE_OUT)
	tween.tween_property(opponent_shield_bar, "value", b.current_shield, duration).set_ease(Tween.EASE_OUT)

func _on_battle_ended(winner: Spider, loser: Spider) -> void:
	_update_bars()
	
	# Object reference comparison fixes winner detection when names match
	var player_won := (winner == battle_controller.spider_a)
	if player_won:
		Economy.add_money(_bet_reward)
		result_label.text = "You won! +₱%d" % _bet_reward
		result_label.modulate = Color(0.435, 0.812, 0.592)
		
		BattleContext.mark_current_challenger_defeated()
		
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
