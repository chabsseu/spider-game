# Inddor spawn
extends Node2D

@export_file("*.tscn") var overworld_scene_path: String = "res://Scenes/Map/blk_5.tscn"
@export var indoor_spawn_position: Vector2 = Vector2(156, 170) # Inside door coordinate

func _ready() -> void:
	# If we have a saved player instance from the GameManager, add them to this room!
	if GameManager.player_instance:
		# Add player to the scene tree
		add_child(GameManager.player_instance)
		# Position them at the indoor entrance
		GameManager.player_instance.global_position = indoor_spawn_position

func _on_exit_door_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
			GameManager.player_instance = body
			body.get_parent().remove_child(body)
			
			# Fade to black, change back to overworld, and fade back in automatically
			TransitionUi.fade_to(func(): 
				get_tree().change_scene_to_file(overworld_scene_path)
			)
