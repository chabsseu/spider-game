extends CanvasLayer

## Autoload singleton (Project Settings -> Autoload, name it exactly
## "CatchMinigameUI") that owns the CatchMinigame UI scene, shows/hides
## it on demand, and routes success/failure back to whichever WebSpot
## triggered it.
##
## Instance your CatchMinigame.tscn as a child of THIS node in the
## editor once you register it as an autoload (autoloaded scenes can
## have children added to them just like any other scene).

signal catch_completed(success: bool, web_spot: Node)

@onready var minigame: CatchMinigame = $CatchMinigame

## World assigns this on _ready(), e.g.:
##   CatchMinigameUI.camera = $Player/Camera2D
var camera: Camera2D = null

var _current_web_spot: Node = null
var _catching: bool = false

func _ready() -> void:
	minigame.hide()
	minigame.catch_succeeded.connect(_on_catch_succeeded)
	minigame.catch_failed.connect(_on_catch_failed)
	minigame.hit_missed.connect(_on_hit_missed)

func _on_hit_missed() -> void:
	if camera:
		camera.shake(4.0, 0.2)

func begin_catch(web_spot: Node, difficulty: float) -> void:
	if _catching:
		return # a catch attempt is already running — ignore repeated triggers

	_catching = true
	_current_web_spot = web_spot
	minigame.show()
	minigame.start_attempt(difficulty)

	# Pause world time and (optionally) player movement while catching.
	if Daynightcycle:
		Daynightcycle.set_paused(true)

func _on_catch_succeeded() -> void:
	_catching = false
	minigame.hide()
	if Daynightcycle:
		Daynightcycle.set_paused(false)

	catch_completed.emit(true, _current_web_spot)

	if is_instance_valid(_current_web_spot):
		var caught_species: SpiderSpecies = _current_web_spot.species
		if caught_species:
			var added := SpiderContainer.add_spider(caught_species)
			if added:
				print("Caught a ", caught_species.species_name, "! Added to container.")
			else:
				print("Caught a ", caught_species.species_name, ", but the container is full!")
		_current_web_spot.queue_free()
	_current_web_spot = null

func _on_catch_failed() -> void:
	_catching = false
	minigame.hide()
	if Daynightcycle:
		Daynightcycle.set_paused(false)

	catch_completed.emit(false, _current_web_spot)

	# Spider "escapes" — remove the web spot either way for now.
	if is_instance_valid(_current_web_spot):
		_current_web_spot.queue_free()
	_current_web_spot = null
