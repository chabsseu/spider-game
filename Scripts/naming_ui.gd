extends CanvasLayer

## Autoload singleton (name it "NamingUI"). Pokemon-style "Give a
## nickname?" popup shown right after catching a spider. Call
## NamingUI.prompt(caught_spider) to show it for that spider.
##
## Pauses the whole game tree while open, so the player can't move
## while typing — process_mode ALWAYS keeps this UI itself running
## even while paused.

@onready var panel: Control = $Panel
@onready var message_label: Label = $Panel/MessageLabel
@onready var name_input: LineEdit = $Panel/NameInput
@onready var confirm_button: Button = $Panel/ConfirmButton
@onready var skip_button: Button = $Panel/SkipButton

var _target_spider: CaughtSpider

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.hide()
	confirm_button.pressed.connect(_on_confirm)
	skip_button.pressed.connect(_on_skip)
	name_input.text_submitted.connect(func(_text): _on_confirm())

func prompt(caught_spider: CaughtSpider) -> void:
	_target_spider = caught_spider
	var species_name := caught_spider.species.species_name if caught_spider.species else "spider"
	message_label.text = "You caught a %s! Give it a nickname?" % species_name
	name_input.text = ""
	panel.show()
	get_tree().paused = true
	name_input.grab_focus()

func _on_confirm() -> void:
	var entered := name_input.text.strip_edges()
	if entered != "":
		_target_spider.nickname = entered
	_close()

func _on_skip() -> void:
	_close()

func _close() -> void:
	panel.hide()
	get_tree().paused = false