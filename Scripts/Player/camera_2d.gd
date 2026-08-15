extends Camera2D

func _ready() -> void:
	var tilemap: TileMap = get_node("/root/World/TileMap") # adjust path to match your scene tree
	var used_rect: Rect2i = tilemap.get_used_rect()
	var tile_size: Vector2i = tilemap.tile_set.tile_size

	limit_left = used_rect.position.x * tile_size.x
	limit_top = used_rect.position.y * tile_size.y
	limit_right = used_rect.end.x * tile_size.x
	limit_bottom = used_rect.end.y * tile_size.y