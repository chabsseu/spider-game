extends Node2D
class_name WebSpot

## A spider web the player can find and catch at night. Placeholder
## visual for now (a simple drawn shape) — swap in a real sprite later
## by removing the _draw() call and adding a Sprite2D/AnimatedSprite2D
## child instead; everything else (detection, interaction) stays the same.

signal player_entered_range
signal player_exited_range

@export var species: SpiderSpecies
@export var interact_action: String = "ui_accept" ## button the player presses to start the catch attempt

@onready var detection_area: Area2D = $DetectionArea

var player_in_range: bool = false
var _player_ref: Node2D = null

func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	queue_redraw()

func _draw() -> void:
	# Bright placeholder so it's easy to spot while prototyping.
	# Swap this out for real art later.
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 1.0, 1.0, 1.0))
	draw_arc(Vector2.ZERO, 10.0, 0, TAU, 16, Color(1.0, 1.0, 1.0, 0.8), 2.0)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed(interact_action):
		_start_catch()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		_player_ref = body
		player_entered_range.emit()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		_player_ref = null
		player_exited_range.emit()

func _start_catch() -> void:
	# Hand off to whatever global reference holds your CatchMinigame UI.
	if not CatchMinigameUI:
		push_warning("No CatchMinigameUI autoload found — wire this up once your catch UI is set up.")
		return

	if not species:
		push_warning("This WebSpot has no species assigned.")
		return

	CatchMinigameUI.begin_catch(self, species.difficulty)