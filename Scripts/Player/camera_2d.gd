extends Camera2D

@export var target: Node2D          # Drag your Player node here in the Inspector
@export var smoothness: float = 8.5   # Higher = faster tracking, Lower = looser/smoother lag

var map_min: Vector2 = Vector2.ZERO
var map_max: Vector2 = Vector2.ZERO
var viewport_half_size: Vector2 = Vector2.ZERO

# --- Screen Shake Variables ---
var _shake_strength: float = 0.0 
var _shake_duration: float = 0.0 
var _rng := RandomNumberGenerator.new() 

func _ready() -> void:
	_rng.randomize()
	
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

# --- Screen Shake Logic ---
func _process(delta: float) -> void: 
	if _shake_duration > 0.0: 
		_shake_duration -= delta 
		offset = Vector2( 
			_rng.randf_range(-_shake_strength, _shake_strength), 
			_rng.randf_range(-_shake_strength, _shake_strength) 
		) 
		if _shake_duration <= 0.0: 
			offset = Vector2.ZERO 

## Call this from anywhere with a reference to the camera, e.g. 
## camera.shake(4.0, 0.2) for a small quick shake. 
func shake(strength: float = 4.0, duration: float = 0.2) -> void: 
	_shake_strength = strength 
	_shake_duration = duration

# Called by your world script to pass the tilemap boundaries
func set_map_bounds(min_pos: Vector2, max_pos: Vector2) -> void: 
	map_min = min_pos 
	map_max = max_pos