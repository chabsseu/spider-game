extends CharacterBody2D
class_name TraderNPC

@export var species_for_sale: Array[SpiderSpecies] = []
@export var greeting_lines: Array[String] = ["Looking for spiders? I've got a few spiders worth your while."]
@export var speaker_name: String = "Alvin"
@export var interact_action: String = "ui_accept"

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

var player_in_range: bool = false
var is_conversing: bool = false
var facing_direction: Vector2 = Vector2.DOWN
var _player: Node2D = null

func _ready() -> void:
    detection_area.body_entered.connect(_on_body_entered)
    detection_area.body_exited.connect(_on_body_exited)
    play_idle()

func _unhandled_input(event: InputEvent) -> void:
    if not player_in_range or is_conversing:
        return

    if event.is_action_pressed(interact_action):
        get_viewport().set_input_as_handled()
        _start_conversation()

func _start_conversation() -> void:
    is_conversing = true

    _face_player()
    DialogUI.say(greeting_lines, speaker_name)
    await DialogUI.finished

    # Small timer buffer ensures key release happens before shop opens
    await get_tree().create_timer(0.05, true, false, true).timeout

    TraderShopUi.open(species_for_sale)
    is_conversing = false

func _face_player() -> void:
    if _player == null:
        return

    var to_player := _player.global_position - global_position
    if abs(to_player.x) > abs(to_player.y):
        facing_direction = Vector2.RIGHT if to_player.x > 0 else Vector2.LEFT
    else:
        facing_direction = Vector2.DOWN if to_player.y > 0 else Vector2.UP

    play_idle()

func play_idle() -> void:
    match facing_direction:
        Vector2.RIGHT: animated_sprite.play("idle_right")
        Vector2.LEFT: animated_sprite.play("idle_left")
        Vector2.DOWN: animated_sprite.play("idle_down")
        Vector2.UP: animated_sprite.play("idle_up")

func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        player_in_range = true
        _player = body

func _on_body_exited(body: Node2D) -> void:
    if body.is_in_group("player"):
        TraderShopUi.close()
        player_in_range = false
        _player = null