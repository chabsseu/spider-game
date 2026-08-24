extends CanvasLayer

## Autoload singleton (name it "BattleUI"). Runs a battle between the
## player's chosen CaughtSpider and an opponent SpiderSpecies, using
## the BattleController gauge-race engine. Shows health/shield bars
## live, then the result, then pays out bet_reward on a win.

@onready var panel: Control = $Panel
@onready var player_name_label: Label = $Panel/PlayerName
@onready var player_health_bar: ProgressBar = $Panel/PlayerHealthBar
@onready var player_shield_bar: ProgressBar = $Panel/PlayerShieldBar
@onready var opponent_name_label: Label = $Panel/OpponentName
@onready var opponent_health_bar: ProgressBar = $Panel/OpponentHealthBar
@onready var opponent_shield_bar: ProgressBar = $Panel/OpponentShieldBar
@onready var result_label: Label = $Panel/ResultLabel
@onready var close_button: Button = $Panel/CloseButton
@onready var battle_controller: BattleController = $BattleController

var _bet_reward: int = 0

func _ready() -> void:
	panel.hide()
	close_button.hide()
	close_button.pressed.connect(_on_close_pressed)
	battle_controller.attack_landed.connect(_on_attack_landed)
	battle_controller.battle_ended.connect(_on_battle_ended)

func start_battle(caught_spider: CaughtSpider, opponent_species: SpiderSpecies, bet_reward: int) -> void:
	_bet_reward = bet_reward
	result_label.text = ""
	close_button.hide()

	var player_spider := Spider.from_species(caught_spider.species)
	var opponent_spider := Spider.from_species(opponent_species)

	player_name_label.text = player_spider.spider_name
	opponent_name_label.text = opponent_spider.spider_name

	panel.show()
	battle_controller.start_battle(player_spider, opponent_spider)
	_update_bars()

func _on_attack_landed(_attacker: Spider, _defender: Spider, _result: Dictionary) -> void:
	_update_bars()

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
	var player_won := winner.spider_name == player_name_label.text
	if player_won:
		Economy.add_money(_bet_reward)
		result_label.text = "You won! +₱%d" % _bet_reward
		result_label.modulate = Color(0.435, 0.812, 0.592)
	else:
		result_label.text = "You lost..."
		result_label.modulate = Color(0.847, 0.353, 0.188)
	close_button.show()

func _on_close_pressed() -> void:
	panel.hide()