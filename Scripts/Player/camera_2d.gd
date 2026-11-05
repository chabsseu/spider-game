extends Camera2D

@export var target: Node2D          # Drag your Player node here in the Inspector
@export var smoothness: float = 8.5   # Higher = faster tracking, Lower = looser/smoother lag

var map_min: Vector2 = Vector2.ZERO
var map_max: Vector2 = Vector2.ZERO
var viewport_half_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Calculate viewport half-size dynamically based on zoom
	var vp_size = get_viewport().get_visible_rect().size
	viewport_half_size = Vector2(vp_size.x / (2.0 * zoom.x), vp_size.y / (2.0 * zoom.y))
	
	# Disable built-in limits so our smooth clamping takes full control
	limit_left = -10000000
	limit_right = 10000000
	limit_top = -10000000
	limit_bottom = 10000000

func _physics_process(delta: float) -> void:
	if not target:
		return

	# 1. Get the player's current position as our target
	var target_pos = target.global_position

	# 2. Smoothly interpolate (lerp) the camera's position towards the player
	global_position = global_position.lerp(target_pos, smoothness * delta)

	# 3. Clamp the camera position so the screen edges stay perfectly inside the tile boundaries
	global_position.x = clamp(global_position.x, map_min.x + viewport_half_size.x, map_max.x - viewport_half_size.x)
	global_position.y = clamp(global_position.y, map_min.y + viewport_half_size.y, map_max.y - viewport_half_size.y)

# Called by your world script to pass the tilemap boundaries
func set_map_bounds(min_pos: Vector2, max_pos: Vector2) -> void:
	map_min = min_pos
	map_max = max_pos