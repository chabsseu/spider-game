#Outdoor spawn
extends Area2D

@export_file("*.tscn") var indoor_scene_path: String = ""
@export var spawn_offset: Vector2 = Vector2(0, 8)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.return_world_position = global_position + spawn_offset
		
		# Save the player instance and remove them from the overworld tree temporarily
		GameManager.player_instance = body
		body.get_parent().remove_child(body)
		
		# Trigger the transition and pass the scene change as a callable action
		TransitionUi.fade_to(func(): 
			get_tree().change_scene_to_file(indoor_scene_path)
		)
