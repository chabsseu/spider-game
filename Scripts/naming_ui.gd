extends CanvasLayer

## Autoload singleton (name it "NamingUi"). Pokemon-style "Give a
## nickname?" popup shown right after catching or buying a spider. Call
## NamingUi.prompt(caught_spider) to show it for that spider.

signal closed

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

func prompt(caught_spider: CaughtSpider, action_verb: String = "caught") -> void:
	_target_spider = caught_spider
	var species_name := caught_spider.species.species_name if caught_spider.species else "spider"
	message_label.text = "You %s a %s! Give it a nickname?" % [action_verb, species_name]
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
	closed.emit()