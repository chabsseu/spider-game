extends Node

@onready var tilemap: TileMap = $TileMap
@onready var camera: Camera2D = $Player/Camera2D
@onready var canvas_modulate: CanvasModulate = $CanvasModulate

func _ready() -> void:
	Daynightcycle.canvas_modulate = canvas_modulate
	CatchMinigameUI.camera = camera

	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_size: Vector2i = tilemap.tile_set.tile_size

	camera.limit_left = used_rect.position.x * tile_size.x
	camera.limit_top = used_rect.position.y * tile_size.y
	camera.limit_right = used_rect.end.x * tile_size.x
	camera.limit_bottom = used_rect.end.y * tile_size.y