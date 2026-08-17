extends Camera2D

## Add this to your existing camera_2d.gd (or merge with whatever's
## already there, like the camera-limit code from earlier).

var _shake_strength: float = 0.0
var _shake_duration: float = 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	# ...your existing camera-limit setup code stays here too

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