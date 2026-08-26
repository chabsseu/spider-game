extends CanvasLayer

## Autoload singleton (name it "BattleSelectUI"). Shows the player's
## caught spiders and lets them pick one to send into a fight against
## opponent_species. On pick, hands off to BattleContext to start the
## battle scene transition.

@onready var panel: Control = $Panel
@onready var header: Label = $Panel/Header
@onready var list: VBoxContainer = $Panel/List
@onready var cancel_button: Button = $Panel/CancelButton

var _opponent_species: SpiderSpecies
var _bet_reward: int
var _challenger_id: String = ""

func _ready() -> void:
	panel.hide()
	cancel_button.pressed.connect(_close)

func open(opponent_species: SpiderSpecies, bet_reward: int, challenger_id: String = "") -> void:
	_opponent_species = opponent_species
	_bet_reward = bet_reward
	_challenger_id = challenger_id
	panel.show()
	_refresh()

func _close() -> void:
	panel.hide()

func _refresh() -> void:
	header.text = "Choose your spider (bet: ₱%d)" % _bet_reward

	for child in list.get_children():
		child.queue_free()

	for spider in SpiderContainer.get_spiders():
		var row := HBoxContainer.new()

		var label := Label.new()
		var name_text := spider.species.species_name if spider.species else "Unknown Spider"
		label.text = name_text
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var fight_button := Button.new()
		fight_button.text = "Fight!"
		fight_button.pressed.connect(func(): _pick(spider))
		row.add_child(fight_button)

		list.add_child(row)

func _pick(spider: CaughtSpider) -> void:
	panel.hide()
	var current_scene_path := get_tree().current_scene.scene_file_path
	BattleContext.start_battle(spider, _opponent_species, _bet_reward, current_scene_path, _challenger_id)