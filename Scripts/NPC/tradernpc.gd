extends CharacterBody2D
class_name TraderNPC

@export var species_for_sale: Array[SpiderSpecies] = []
@export var greeting_lines: Array[String] = ["Looking for spiders? I've got a few spiders worth your while."]
@export var speaker_name: String = "Alvin"
@export var interact_action: String = "ui_accept"

@onready var detection_area: Area2D = $DetectionArea

var player_in_range: bool = false
var is_conversing: bool = false

func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_conversing:
		return

	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_start_conversation()

func _start_conversation() -> void:
	is_conversing = true

	DialogUI.say(greeting_lines, speaker_name)
	await DialogUI.finished

	# Small timer buffer ensures key release happens before shop opens
	await get_tree().create_timer(0.05, true, false, true).timeout

	TraderShopUi.open(species_for_sale)
	is_conversing = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		TraderShopUi.close()
		player_in_range = false