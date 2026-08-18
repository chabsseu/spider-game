extends CanvasLayer

## Standalone, self-contained container panel. Set this up as an
## Autoload (Project Settings -> Autoload, name it "ContainerUI")
## pointing at ContainerUI.tscn — it'll then automatically appear in
## every scene without needing to be manually added per-world.
##
## Press Tab (or whatever toggle_action you set) to show/hide it.

@export var toggle_action: String = "ui_focus_next" ## default Tab in Godot's Input Map

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
		var name_text := spider.species.species_name if spider.species else "Unknown Spider"
		label.text = "- %s (caught %s)" % [name_text, spider.caught_time]
		list.add_child(label)

	if SpiderContainer.get_count() == 0:
		var empty_label := Label.new()
		empty_label.text = "(empty)"
		empty_label.modulate = Color(0.7, 0.7, 0.7)
		list.add_child(empty_label)