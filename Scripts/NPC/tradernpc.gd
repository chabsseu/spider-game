extends CharacterBody2D
class_name TraderNpc

@export var species_for_sale: Array[SpiderSpecies] = []
@export var interact_action: String = "ui_accept"

@onready var detection_area: Area2D = $DetectionArea

var player_in_range: bool = false


func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed(interact_action):
		TraderShopUi.open(species_for_sale)

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true


func _on_detection_area_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		TraderShopUi.close()
		player_in_range = false
