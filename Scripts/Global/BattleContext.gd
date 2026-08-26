extends Node

## Autoload singleton (name it "BattleContext").
## Holds battle data, return positions, world persistence, and defeated NPC tracking.

var player_spider_data: CaughtSpider
var opponent_species: SpiderSpecies
var bet_reward: int = 0
var return_scene_path: String = "res://Scenes/World/world.tscn"

var _return_position: Vector2 = Vector2.ZERO
var _has_return_position: bool = false

var _current_challenger_id: String = ""
var persistent_world_data: Dictionary = {}
var active_web_spots_data: Array[Dictionary] = []
var _defeated_challenger_ids: Array[String] = []

func start_battle(spider: CaughtSpider, opponent: SpiderSpecies, reward: int, current_scene_path: String = "", challenger_id: String = "") -> void:
	player_spider_data = spider
	opponent_species = opponent
	bet_reward = reward
	_current_challenger_id = challenger_id
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

## --- Defeated Challenger Tracking ---

func get_npc_id(npc: Node) -> String:
	if "npc_id" in npc and not str(npc.npc_id).is_empty():
		return str(npc.npc_id)
	return npc.name

func is_npc_defeated(npc: Node) -> bool:
	var id := get_npc_id(npc)
	return _defeated_challenger_ids.has(id)

func mark_current_challenger_defeated() -> void:
	if _current_challenger_id != "" and not _defeated_challenger_ids.has(_current_challenger_id):
		_defeated_challenger_ids.append(_current_challenger_id)
		print("Challenger marked as defeated: ", _current_challenger_id)