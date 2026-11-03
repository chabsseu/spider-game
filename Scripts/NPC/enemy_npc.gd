extends CharacterBody2D
class_name ChallengerNPC

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var npc_id: String = ""
@export var opponent_species: SpiderSpecies
@export var bet_reward: int = 30

@export var speaker_name: String = "Kevin"

@export var challenge_lines: Array[String] = [
	"Think your spider's got what it takes? Let's bet on it!"
]

@export var defeated_lines: Array[String] = [
	"You already beat my spider. No rematch."
]

@export var no_spiders_lines: Array[String] = [
	"Come back when you've got a spider to fight with."
]

@export var interact_action: String = "ui_accept"

@onready var detection_area: Area2D = $DetectionArea

var player_in_range: bool = false
var is_conversing: bool = false
var facing_direction: Vector2 = Vector2.DOWN
var _player: Node2D = null

enum ConversationType {
	NONE,
	DEFEATED,
	NO_SPIDERS,
	CHALLENGE
}


func _ready() -> void:
	add_to_group("npc")

	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_conversing:
		return

	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_try_start_challenge()

# func _process(_delta: float) -> void:
# 	if not player_in_range:
# 		return

# 	if is_conversing:
# 		return

# 	if Input.is_action_just_pressed(interact_action):
# 		_try_start_challenge()


func _try_start_challenge() -> void:
	is_conversing = true

	_face_player()

	var conversation_type: ConversationType = ConversationType.NONE
	var lines: Array[String] = []

	# Already defeated.
	if BattleContext.is_npc_defeated(self):
		conversation_type = ConversationType.DEFEATED
		lines = defeated_lines

	# Player has no spiders.
	elif SpiderContainer.get_count() == 0:
		conversation_type = ConversationType.NO_SPIDERS
		lines = no_spiders_lines

	# NPC has no opponent.
	elif opponent_species == null:
		push_warning("ChallengerNPC has no opponent_species assigned.")

		is_conversing = false
		return

	# Normal challenge.
	else:
		conversation_type = ConversationType.CHALLENGE
		lines = challenge_lines

	# Start dialogue.
	DialogUI.say(lines, speaker_name)

	# Wait for dialogue to finish.
	await DialogUI.finished

	# Dialogue is done.
	is_conversing = false

	# Do whatever this conversation requires.
	if conversation_type == ConversationType.CHALLENGE:
		BattleSelectUi.open(
			opponent_species,
			bet_reward,
			BattleContext.get_npc_id(self)
		)


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		_player = body

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		_player = null
		
func play_idle() -> void:
	match facing_direction:
		Vector2.RIGHT: animated_sprite.play("idle_right")
		Vector2.LEFT: animated_sprite.play("idle_left")
		Vector2.DOWN: animated_sprite.play("idle_down")
		Vector2.UP: animated_sprite.play("idle_up")

func _face_player() -> void:
	if _player == null:
		return
		
	var to_player := _player.global_position - global_position
	if abs(to_player.x) > abs(to_player.y):
		facing_direction = Vector2.RIGHT if to_player.x > 0 else Vector2.LEFT
	else:
		facing_direction = Vector2.DOWN if to_player.y > 0 else Vector2.UP
		
	velocity = Vector2.ZERO
	play_idle()
