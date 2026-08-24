extends CanvasLayer

## Autoload singleton (Project Settings -> Autoload, name it exactly
## "TraderShopUI") pointing at TraderShopUI.tscn. Opened by TraderNPC
## when the player interacts with it. Shows two sections: spiders for
## sale (buy) and the player's own caught spiders (sell).

@onready var panel: Control = $Panel
@onready var money_label: Label = $Panel/MoneyLabel
@onready var for_sale_list: VBoxContainer = $Panel/ForSaleList
@onready var your_spiders_list: VBoxContainer = $Panel/YourSpidersList
@onready var close_button: Button = $Panel/CloseButton

var _current_species_for_sale: Array[SpiderSpecies] = []

func _ready() -> void:
	panel.hide()
	close_button.pressed.connect(close)
	SpiderContainer.container_changed.connect(_refresh)
	Economy.money_changed.connect(_on_money_changed)

func open(species_for_sale: Array[SpiderSpecies]) -> void:
	_current_species_for_sale = species_for_sale
	panel.show()
	_refresh()

func close() -> void:
	panel.hide()

func _on_money_changed(_new_amount: int) -> void:
	if panel.visible:
		_refresh()

func _refresh() -> void:
	money_label.text = "Money: ₱%d" % Economy.money

	for child in for_sale_list.get_children():
		child.queue_free()
	for child in your_spiders_list.get_children():
		child.queue_free()

	# --- For sale (buy) ---
	for species in _current_species_for_sale:
		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = "%s — ₱%d" % [species.species_name, species.buy_price]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var buy_button := Button.new()
		buy_button.text = "Buy"
		buy_button.disabled = Economy.money < species.buy_price or SpiderContainer.is_full()
		buy_button.pressed.connect(func(): SpiderContainer.buy_spider(species))
		row.add_child(buy_button)

		for_sale_list.add_child(row)

	# --- Your spiders (sell) ---
	for spider in SpiderContainer.get_spiders():
		var row := HBoxContainer.new()

		var label := Label.new()
		var name_text := spider.species.species_name if spider.species else "Unknown Spider"
		var price := spider.species.sell_price if spider.species else 0
		label.text = "%s (caught %s)" % [name_text, spider.caught_time]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(label)

		var sell_button := Button.new()
		sell_button.text = "Sell ₱%d" % price
		sell_button.pressed.connect(func(): SpiderContainer.sell_spider(spider))
		row.add_child(sell_button)

		your_spiders_list.add_child(row)

	if SpiderContainer.get_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "(you have no spiders)"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		your_spiders_list.add_child(empty_label)