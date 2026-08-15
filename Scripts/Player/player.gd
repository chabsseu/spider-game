extends CharacterBody2D

@export var speed: float = 100.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var facing_direction: Vector2 = Vector2.DOWN

func _physics_process(delta: float) -> void:
	var input_direction = get_4_directional_input()
	velocity = input_direction * speed
	move_and_slide()

	update_animation(input_direction)

func get_4_directional_input() -> Vector2:
	var horizontal := Input.get_axis("A", "D")
	var vertical := Input.get_axis("W", "S")

	if horizontal != 0 and vertical != 0:
		if Input.is_action_just_pressed("A") or Input.is_action_just_pressed("D"):
			vertical = 0
		elif Input.is_action_just_pressed("W") or Input.is_action_just_pressed("S"):
			horizontal = 0
		else:
			vertical = 0

	return Vector2(horizontal, vertical)

func update_animation(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		play_idle()
		return

	if direction.x > 0:
		facing_direction = Vector2.RIGHT
		animated_sprite.play("walk_right")
	elif direction.x < 0:
		facing_direction = Vector2.LEFT
		animated_sprite.play("walk_left")
	elif direction.y > 0:
		facing_direction = Vector2.DOWN
		animated_sprite.play("walk_down")
	elif direction.y < 0:
		facing_direction = Vector2.UP
		animated_sprite.play("walk_up")

func play_idle() -> void:
	if facing_direction == Vector2.RIGHT:
		animated_sprite.play("idle_right")
	elif facing_direction == Vector2.LEFT:
		animated_sprite.play("idle_left")
	elif facing_direction == Vector2.DOWN:
		animated_sprite.play("idle_down")
	elif facing_direction == Vector2.UP:
		animated_sprite.play("idle_up")