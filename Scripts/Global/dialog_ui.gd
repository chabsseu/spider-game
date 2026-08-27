extends CanvasLayer

signal finished

@onready var panel: Control = $Panel
@onready var text_label: RichTextLabel = $Panel/TextLabel
@onready var continue_indicator: Label = $Panel/ContinueIndicator
@onready var speaker_label: Label = $Panel/SpeakerLabel

@export var reveal_speed: float = 0.02
@export var advance_action: String = "ui_accept"

var _lines: Array[String] = []
var _current_line_index: int = 0
var _current_full_text: String = ""

var _reveal_timer: float = 0.0
var _revealed_chars: int = 0
var _is_revealing: bool = false
var _blink_timer: float = 0.0
var _input_cooldown: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	continue_indicator.hide()

func say(lines: Array[String], speaker_name: String = "") -> void:
	if lines.is_empty():
		finished.emit.call_deferred()
		return

	_lines = lines.duplicate()
	_current_line_index = 0
	_current_full_text = ""

	speaker_label.text = speaker_name
	speaker_label.visible = not speaker_name.is_empty()

	panel.show()
	get_tree().paused = true
	_input_cooldown = 0.15
	_show_line(0)

func _show_line(index: int) -> void:
	if index < 0 or index >= _lines.size():
		_close()
		return

	_current_full_text = _lines[index]
	_revealed_chars = 0
	_reveal_timer = 0.0
	_blink_timer = 0.0
	_is_revealing = true

	text_label.text = ""
	continue_indicator.hide()

func _process(delta: float) -> void:
	if not panel.visible:
		return

	if _input_cooldown > 0.0:
		_input_cooldown -= delta

	if _is_revealing:
		_reveal_timer += delta
		while _reveal_timer >= reveal_speed and _revealed_chars < _current_full_text.length():
			_reveal_timer -= reveal_speed
			_revealed_chars += 1
			text_label.text = _current_full_text.substr(0, _revealed_chars)

		if _revealed_chars >= _current_full_text.length():
			_is_revealing = false
			continue_indicator.show()
	else:
		_blink_timer += delta
		if _blink_timer >= 0.45:
			_blink_timer = 0.0
			continue_indicator.visible = not continue_indicator.visible

func _unhandled_input(event: InputEvent) -> void:
	if not panel.visible or _input_cooldown > 0.0:
		return

	if event.is_action_pressed(advance_action):
		get_viewport().set_input_as_handled()
		_advance()

func _advance() -> void:
	if _is_revealing:
		_revealed_chars = _current_full_text.length()
		text_label.text = _current_full_text
		_is_revealing = false
		_input_cooldown = 0.1
		continue_indicator.show()
		return

	_current_line_index += 1
	if _current_line_index >= _lines.size():
		_close()
	else:
		_input_cooldown = 0.1
		_show_line(_current_line_index)

func _close() -> void:
	panel.hide()
	continue_indicator.hide()
	speaker_label.hide()
	text_label.text = ""

	_lines.clear()
	_current_line_index = 0
	_current_full_text = ""
	_revealed_chars = 0
	_reveal_timer = 0.0
	_blink_timer = 0.0
	_is_revealing = false

	get_tree().paused = false
	finished.emit()