extends CanvasLayer
signal transition_finished

@onready var fade_rect: ColorRect = $FadeRect
@onready var circle_rect: ColorRect = $CircleRect

var _circle_material: ShaderMaterial
var _max_radius: float = 0.0

func _ready() -> void:
	layer = 100 # draw on top of everything else

	fade_rect.color = Color(0, 0, 0, 1)
	fade_rect.modulate.a = 0.0
	fade_rect.hide()

	# Build the shader material fresh in code — more reliable than
	# depending on a pre-wired .tres/.tscn reference.
	var shader: Shader = load("res://Scripts/Global/circle_wipe.gdshader")
	if not shader:
		push_error("TransitionUI could not load circle_wipe.gdshader — check the path.")
	_circle_material = ShaderMaterial.new()
	_circle_material.shader = shader
	circle_rect.material = _circle_material
	circle_rect.color = Color(1, 1, 1, 1) # irrelevant once the shader overrides COLOR
	circle_rect.hide()

	var viewport_size := get_viewport().get_visible_rect().size
	_max_radius = viewport_size.length() * 0.6
	_circle_material.set_shader_parameter("screen_size", viewport_size)
	_circle_material.set_shader_parameter("center", Vector2(0.5, 0.5))
	_circle_material.set_shader_parameter("radius", _max_radius)

# --- Fade transition ---

func fade_to(action: Callable, duration: float = 0.4) -> void:
	await _fade_cover(duration)
	action.call()
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade_reveal(duration)
	transition_finished.emit()

func _fade_cover(duration: float) -> void:
	fade_rect.show()
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, duration)
	await tween.finished

func _fade_reveal(duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, duration)
	await tween.finished
	fade_rect.hide()

# --- Circle wipe transition ---

func circle_to(action: Callable, duration: float = 0.5) -> void:
	await _circle_shrink(duration)
	action.call()
	await get_tree().process_frame
	await get_tree().process_frame
	await _circle_grow(duration)
	transition_finished.emit()

func _circle_shrink(duration: float) -> void:
	circle_rect.show()
	_circle_material.set_shader_parameter("radius", _max_radius)
	var tween := create_tween()
	tween.tween_method(_set_radius, _max_radius, 0.0, duration)
	await tween.finished

func _circle_grow(duration: float) -> void:
	_circle_material.set_shader_parameter("radius", 0.0)
	var tween := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_method(_set_radius, 0.0, _max_radius, duration)
	await tween.finished
	circle_rect.hide()

func _set_radius(value: float) -> void:
	_circle_material.set_shader_parameter("radius", value)