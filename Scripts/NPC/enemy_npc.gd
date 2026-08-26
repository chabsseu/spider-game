extends CharacterBody2D
class_name ChallengerNPC

## Stationary NPC script. Set a unique `npc_id` in the Inspector 
## for every challenger placed in your world (e.g., "brgy1_kid_01").

@export var npc_id: String = ""
@export var opponent_species: SpiderSpecies
@export var bet_reward: int = 30
@export var interact_action: String = "ui_accept"

@onready var detection_area: Area2D = $DetectionArea

var player_in_range: bool = false

func _ready() -> void:
	add_to_group("npc")
	
	# Fallback if no ID is assigned in Inspector
	if npc_id.is_empty():
		npc_id = name
		
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

	# Optional: Check if already defeated on room load
	if BattleContext.is_npc_defeated(self):
		_on_already_defeated()

func _on_already_defeated() -> void:
	print("NPC ", npc_id, " is already defeated.")
	# Optional: Visual indicator or disable collision/interaction
	# $Sprite2D.modulate = Color(0.5, 0.5, 0.5)

func _process(_delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed(interact_action):
		_try_start_challenge()

func _try_start_challenge() -> void:
	if BattleContext.is_npc_defeated(self):
		print("You already beat this spider. No rematch.")
		return

	if SpiderContainer.get_count() == 0:
		print("You have no spiders to fight with!")
		return

	if not opponent_species:
		push_warning("ChallengerNPC has no opponent_species assigned.")
		return

	BattleSelectUi.open(opponent_species, bet_reward, BattleContext.get_npc_id(self))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false