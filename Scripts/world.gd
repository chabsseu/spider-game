extends Node

@onready var tilemap: TileMap = $TileMap
@onready var camera: Camera2D = $Player/Camera2D
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

func _ready() -> void:
	Daynightcycle.canvas_modulate = canvas_modulate
	CatchMinigameUI.camera = camera
	_restore_world_state()
	
	# 1. Calculate exact pixel boundaries of the TileMap
	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_size: Vector2i = tilemap.tile_set.tile_size
	var map_pos: Vector2 = tilemap.global_position

	var map_left = map_pos.x + (used_rect.position.x * tile_size.x)
	var map_top = map_pos.y + (used_rect.position.y * tile_size.y)
	var map_right = map_pos.x + (used_rect.end.x * tile_size.x)
	var map_bottom = map_pos.y + (used_rect.end.y * tile_size.y)

	# 2. Pass these bounds to the smooth camera script
	if camera.has_method("set_map_bounds"):
		camera.set_map_bounds(Vector2(map_left, map_top), Vector2(map_right, map_bottom))

func _restore_world_state() -> void:
	# Hide or disable defeated opponents when re-entering world
	var defeated_list: Array = BattleContext.persistent_world_data.get("defeated_opponents", [])
	
	for opponent in get_tree().get_nodes_in_group("opponents"):
		if opponent.has_meta("npc_id") and opponent.get_meta("npc_id") in defeated_list:
			opponent.queue_free() # or opponent.set_defeated_state()

func trigger_battle_with_npc(npc_node: Node2D, spider: CaughtSpider, opponent_species: SpiderSpecies, reward: int) -> void:
	# Track which NPC we are fighting before scene change
	if npc_node.has_meta("npc_id"):
		BattleContext.persistent_world_data["last_opponent_id"] = npc_node.get_meta("npc_id")
		
	BattleContext.start_battle(spider, opponent_species, reward, scene_file_path)
