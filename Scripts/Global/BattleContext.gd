extends Node

## Autoload singleton ("BattleContext")
## Holds temporary fight parameters AND persistent world data 
## across full scene changes.

var player_spider_data: CaughtSpider
var opponent_species: SpiderSpecies
var bet_reward: int = 0
var return_scene_path: String = "res://Scenes/World/world.tscn"

var _return_position: Vector2 = Vector2.ZERO
var _has_return_position: bool = false
var active_web_spots_data: Array[Dictionary] = []

# Persistent world flags across scene changes
var persistent_world_data: Dictionary = {
	"defeated_opponents": [], # Array of Unique NPC IDs
	"opened_chests": []       # Array of Chest IDs
}

func start_battle(spider: CaughtSpider, opponent: SpiderSpecies, reward: int, current_scene_path: String = "") -> void:
	player_spider_data = spider
	opponent_species = opponent
	bet_reward = reward
	
	if current_scene_path != "":
		return_scene_path = current_scene_path

	var player_node := get_tree().current_scene.get_node_or_null("Player")
	if player_node:
		_return_position = player_node.global_position
		_has_return_position = true

	if Daynightcycle:
		Daynightcycle.set_paused(true)

	get_tree().change_scene_to_file("res://Scenes/World/BattleScene.tscn")

func return_to_world() -> void:
	if Daynightcycle:
		Daynightcycle.set_paused(false)
	get_tree().change_scene_to_file(return_scene_path)

func consume_return_position(player_node: Node2D) -> bool:
	if not _has_return_position:
		return false
	player_node.global_position = _return_position
	_has_return_position = false
	return true