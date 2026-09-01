extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var label: Label = $PanelContainer/Label

# Load your custom Minecraft pixel font
const PIXEL_FONT = preload("res://Minecraft.ttf") # Update to your actual font path

func _ready() -> void:
	panel.hide()
	
	# Apply pixel font and adjust size
	if PIXEL_FONT:
		label.add_theme_font_override("font", PIXEL_FONT)
		label.add_theme_font_size_override("font_size", 16)

func show_tooltip(spider: CaughtSpider, pos: Vector2) -> void:
	if not spider:
		return

	var base := spider.species
	var base_hp := int(base.health) if base and base.health > 0 else 100
	var base_str := int(base.strength) if base and base.strength > 0 else 5
	var base_spd := int(base.speed) if base and base.speed > 0 else 5

	var total_hp := base_hp + spider.bonus_health
	var total_str := base_str + spider.bonus_strength
	var total_spd := base_spd + spider.bonus_speed

	var text_content := "[ %s ]\n" % spider.get_display_name()
	text_content += "HP: %d (%+d)\n" % [total_hp, spider.bonus_health]
	text_content += "STR: %d (%+d)\n" % [total_str, spider.bonus_strength]
	text_content += "SPD: %d (%+d)" % [total_spd, spider.bonus_speed]

	label.text = text_content
	panel.global_position = pos + Vector2(15, 15)
	panel.show()

func hide_tooltip() -> void:
	panel.hide()