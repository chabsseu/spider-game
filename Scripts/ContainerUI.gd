extends CanvasLayer

## Standalone, self-contained container panel. Autoload (name it
## "ContainerUI") pointing at ContainerUI.tscn. Press Tab to toggle.

@export var toggle_action: String = "ui_focus_next"

@onready var panel: Control = $Panel
@onready var header: Label = $Panel/Header
@onready var list: VBoxContainer = $Panel/List

func _ready() -> void:
	panel.hide()
	SpiderContainer.container_changed.connect(_refresh)
	_refresh()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(toggle_action):
		panel.visible = not panel.visible
		if panel.visible:
			_refresh()

func _refresh() -> void:
	header.text = "Container (%d/%d)" % [SpiderContainer.get_count(), SpiderContainer.capacity]

	for child in list.get_children():
		child.queue_free()

	for spider in SpiderContainer.get_spiders():
		var label := Label.new()
		label.text = "- %s (caught %s)" % [spider.get_display_name(), spider.caught_time]
		list.add_child(label)

	if SpiderContainer.get_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "(empty)"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		list.add_child(empty_label)