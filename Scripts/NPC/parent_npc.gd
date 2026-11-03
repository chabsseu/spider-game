extends CharacterBody2D

@export var speed: float = 80.0
@export var wait_time: float = 1.5

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var patrol_points: Array[Vector2] = []
@export var greeting_lines: Array[String] = [""]
@export var interact_action: String = "ui_accept"
@export var speaker_name: String = ""
@onready var detection_area: Area2D = $DetectionArea

var player_in_range: bool = false
var is_conversing: bool = false

var current_point_index: int = 0
var waiting: bool = false
var facing_direction: Vector2 = Vector2.DOWN
var _player: Node2D = null

func _ready() -> void:
	detection_area.body_entered.connect(_on_body_entered)
	detection_area.body_exited.connect(_on_body_exited)
	patrol_points.append(global_position)
	
	# for marker in $PatrolPoints.get_children():
	# 	patrol_points.append(marker.global_position)

func _physics_process(delta: float) -> void:
	if patrol_points.is_empty() or waiting:
		velocity = Vector2.ZERO
		##move_and_slide()
		return

	var target: Vector2 = patrol_points[current_point_index]
	var direction: Vector2 = (target - global_position)

	if direction.length() < 4.0:
		velocity = Vector2.ZERO
		#move_and_slide()
		# update_animation(Vector2.ZERO)
		_pause_then_advance()
		return

	direction = direction.normalized()
	velocity = direction * speed
	#move_and_slide()
	# update_animation(direction)

func _pause_then_advance() -> void:
	waiting = true
	await get_tree().create_timer(wait_time).timeout
	current_point_index = (current_point_index + 1) % patrol_points.size()
	waiting = false

# func update_animation(direction: Vector2) -> void:
# 	if direction == Vector2.ZERO:
# 		play_idle()
# 		return

# 	if abs(direction.x) > abs(direction.y):
# 		facing_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
# 	else:
# 		facing_direction = Vector2.DOWN if direction.y > 0 else Vector2.UP

# 	match facing_direction:
# 		Vector2.RIGHT: animated_sprite.play("walk_right")
# 		Vector2.LEFT: animated_sprite.play("walk_left")
# 		Vector2.DOWN: animated_sprite.play("walk_down")
# 		Vector2.UP: animated_sprite.play("walk_up")

func play_idle() -> void:
	match facing_direction:
		Vector2.RIGHT: animated_sprite.play("idle_right")
		Vector2.LEFT: animated_sprite.play("idle_left")
		Vector2.DOWN: animated_sprite.play("idle_down")
		Vector2.UP: animated_sprite.play("idle_up")

func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range or is_conversing:
		return

	if event.is_action_pressed(interact_action):
		get_viewport().set_input_as_handled()
		_start_conversation()

func _start_conversation() -> void:
	is_conversing = true

	_face_player()
	DialogUI.say(greeting_lines, speaker_name)
	await DialogUI.finished

	is_conversing = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = true
		_player = body

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_in_range = false
		_player = null

func _face_player() -> void:
	if _player == null:
		return
		
	var to_player := _player.global_position - global_position
	if abs(to_player.x) > abs(to_player.y):
		facing_direction = Vector2.RIGHT if to_player.x > 0 else Vector2.LEFT
	else:
		facing_direction = Vector2.DOWN if to_player.y > 0 else Vector2.UP
		
	velocity = Vector2.ZERO
	play_idle()
