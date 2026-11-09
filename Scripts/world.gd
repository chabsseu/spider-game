# world.gd
extends Node

@onready var tilemap: TileMap = $TileMap
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

const PLAYER_SCENE = preload("res://Scenes/Player/player.tscn") # Adjust path if needed

func _ready() -> void:
	Daynightcycle.canvas_modulate = canvas_modulate
	_restore_world_state()
	
	# 1. Calculate exact pixel boundaries of the TileMap
	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_size: Vector2i = tilemap.tile_set.tile_size
	var map_pos: Vector2 = tilemap.global_position

	var map_left = map_pos.x + (used_rect.position.x * tile_size.x)
	var map_top = map_pos.y + (used_rect.position.y * tile_size.y)
	var map_right = map_pos.x + (used_rect.end.x * tile_size.x)
	var map_bottom = map_pos.y + (used_rect.end.y * tile_size.y)

	# 2. Handle the persistent player instance
	var player = GameManager.player_instance
	if not player:
		player = PLAYER_SCENE.instantiate()
		add_child(player)
		player.global_position = Vector2(970, 305) # Default spawn point
	else:
		if player.get_parent() != self:
			add_child(player)
			
		if GameManager.return_world_position != Vector2.ZERO:
			player.global_position = GameManager.return_world_position + Vector2(0, 16)
			GameManager.return_world_position = Vector2.ZERO

	# Ensure the player is always in the "player" group
	if not player.is_in_group("player"):
		player.add_to_group("player")

	# 3. Setup camera reference
	var camera = player.get_node_or_null("Camera2D")
	if camera:
		camera.make_current()
		CatchMinigameUI.camera = camera
		if camera.has_method("set_map_bounds"):
			camera.set_map_bounds(Vector2(map_left, map_top), Vector2(map_right, map_bottom))

func _restore_world_state() -> void:
	var defeated_list: Array = BattleContext.persistent_world_data.get("defeated_opponents", [])
	for opponent in get_tree().get_nodes_in_group("opponents"):
		if opponent.has_meta("npc_id") and opponent.get_meta("npc_id") in defeated_list:
			opponent.queue_free()

func trigger_battle_with_npc(npc_node: Node2D, spider: CaughtSpider, opponent_species: SpiderSpecies, reward: int) -> void:
	if npc_node.has_meta("npc_id"):
		BattleContext.persistent_world_data["last_opponent_id"] = npc_node.get_meta("npc_id")
	BattleContext.start_battle(spider, opponent_species, reward, scene_file_path)