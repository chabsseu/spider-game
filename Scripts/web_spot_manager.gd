extends Node2D
class_name WebSpotManager

@export var web_spot_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(-400, -300, 800, 600)
@export var min_spawns: int = 2
@export var max_spawns: int = 5
@export var species_pool: Array[SpiderSpecies] = []

var _active_spots: Array[WebSpot] = []

func _ready() -> void:
	Daynightcycle.night_started.connect(_on_night_started)
	Daynightcycle.day_started.connect(_on_day_started)

	# 1. Restore saved spots from BattleContext if returning from battle
	if not BattleContext.active_web_spots_data.is_empty():
		_restore_spots_from_context()
	# 2. Otherwise, if starting a fresh load at night, spawn new ones
	elif Daynightcycle.is_night:
		_on_night_started()

func _exit_tree() -> void:
	# Save active web spots before this scene is destroyed
	save_spots_to_context()

func save_spots_to_context() -> void:
	BattleContext.active_web_spots_data.clear()
	for spot in _active_spots:
		if is_instance_valid(spot):
			BattleContext.active_web_spots_data.append({
				"position": spot.position,
				"species": spot.species
			})

func _restore_spots_from_context() -> void:
	_clear_spots()
	for data in BattleContext.active_web_spots_data:
		_spawn_at_position(data["position"], data["species"])
	# Clear after loading so it won't duplicate on non-battle reloads
	BattleContext.active_web_spots_data.clear()

func _on_night_started() -> void:
	_clear_spots()
	var count := randi_range(min_spawns, max_spawns)
	for i in count:
		_spawn_one()

func _on_day_started() -> void:
	_clear_spots()
	BattleContext.active_web_spots_data.clear()

func _spawn_one() -> void:
	if species_pool.is_empty():
		push_warning("WebSpotManager has no species in its species_pool.")
		return

	var pos := Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	var chosen_species: SpiderSpecies = species_pool[randi() % species_pool.size()]
	_spawn_at_position(pos, chosen_species)

func _spawn_at_position(pos: Vector2, species: SpiderSpecies) -> void:
	if not web_spot_scene:
		push_warning("WebSpotManager has no web_spot_scene assigned.")
		return

	var spot: WebSpot = web_spot_scene.instantiate()
	spot.position = pos
	spot.species = species
	print("Spawned web spot at: ", spot.position)
	add_child(spot)
	_active_spots.append(spot)

func _clear_spots() -> void:
	for spot in _active_spots:
		if is_instance_valid(spot):
			spot.queue_free()
	_active_spots.clear()