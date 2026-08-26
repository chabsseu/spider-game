extends Node

## Autoload singleton (Project Settings -> Autoload, name it exactly
## "SpiderContainer") that holds the player's caught spiders, up to a
## capacity limit — mirrors the real container-with-dividers idea.
## Buying a bigger container later just means raising `capacity`.

signal spider_added(spider: CaughtSpider)
signal spider_sold(spider: CaughtSpider, price: int)
signal container_full
signal container_changed # fires on any add/remove — UI should listen to this to refresh

@export var capacity: int = 3

var _spiders: Array[CaughtSpider] = []

## Returns the newly created CaughtSpider on success, or null if the
## container is full. Accepts an optional custom nickname.
func add_spider(species: SpiderSpecies, nickname: String = "") -> CaughtSpider:
	if is_full():
		container_full.emit()
		return null

	var current_time := Daynightcycle.get_time_string() if Daynightcycle else ""
	var spider := CaughtSpider.new(species, current_time, nickname)
	_spiders.append(spider)
	spider_added.emit(spider)
	container_changed.emit()
	return spider

func remove_spider(spider: CaughtSpider) -> void:
	_spiders.erase(spider)
	container_changed.emit()

func sell_spider(spider: CaughtSpider) -> void:
	if not _spiders.has(spider):
		return

	var price := spider.species.sell_price if spider.species else 0
	_spiders.erase(spider)
	Economy.add_money(price)
	spider_sold.emit(spider, price)
	container_changed.emit()

## Buys a spider of the given species from the trader. Returns false
## if the player can't afford it or the container is full.
func buy_spider(species: SpiderSpecies, nickname: String = "") -> bool:
	if is_full():
		container_full.emit()
		return false

	if not Economy.spend_money(species.buy_price):
		return false

	return add_spider(species, nickname) != null

func is_full() -> bool:
	return _spiders.size() >= capacity

func get_spiders() -> Array[CaughtSpider]:
	return _spiders

func get_count() -> int:
	return _spiders.size()