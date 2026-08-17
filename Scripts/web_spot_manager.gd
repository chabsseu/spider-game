extends Node2D
class_name WebSpotManager

## Spawns random WebSpot instances within a rectangular area when
## night starts, and clears them when day starts. Attach this as a
## child of your World scene, set spawn_area to cover your grass/
## huntable region, and assign web_spot_scene to WebSpot.tscn.
##
## Requires the DayNightCycle autoload (from earlier) to be set up
## and firing night_started / day_started signals.

@export var web_spot_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(-400, -300, 800, 600) ## world-space rect to spawn within
@export var min_spawns: int = 2
@export var max_spawns: int = 5

var _active_spots: Array[WebSpot] = []

func _ready() -> void:
	Daynightcycle.night_started.connect(_on_night_started)
	Daynightcycle.day_started.connect(_on_day_started)

	# Handle the case where the game starts already at night.
	if Daynightcycle.is_night:
		_on_night_started()

func _on_night_started() -> void:
	_clear_spots() # just in case any are lingering
	var count := randi_range(min_spawns, max_spawns)
	for i in count:
		_spawn_one()
		

func _on_day_started() -> void:
	_clear_spots()

func _spawn_one() -> void:
	if not web_spot_scene:
		push_warning("WebSpotManager has no web_spot_scene assigned.")
		return

	var spot: WebSpot = web_spot_scene.instantiate()
	spot.position = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	# TODO: once you have real spider species, randomize spot.difficulty
	# here based on rarity weights instead of the exported default.
	print("Spawned web spot at: ", spot.position)
	add_child(spot)
	_active_spots.append(spot)

func _clear_spots() -> void:
	for spot in _active_spots:
		if is_instance_valid(spot):
			spot.queue_free()
	_active_spots.clear()