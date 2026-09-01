extends CanvasLayer

@onready var panel: PanelContainer = $PanelContainer
@onready var label: Label = $PanelContainer/Label

# Update this path to your pixel font if needed
const PIXEL_FONT := preload("res://Minecraft.ttf") 

func _ready() -> void:
	panel.hide()
	if PIXEL_FONT:
		label.add_theme_font_override("font", PIXEL_FONT)
		label.add_theme_font_size_override("font_size", 14)

func show_tooltip(spider: CaughtSpider, pos: Vector2) -> void:
	if not spider:
		return

	var base := spider.species
	var base_hp := int(base.health) if base and base.health > 0 else 100
	var base_str := int(base.strength) if base and base.strength > 0 else 5
	var base_spd := int(base.speed) if base and base.speed > 0 else 5
	var base_def := int(base.get("defense")) if base and "defense" in base else 0
	var base_crit := float(base.crit_chance) if base and base.crit_chance > 0.0 else 10.0

	# Extract bonus values from CaughtSpider safely
	var b_def: int = int(spider.get("bonus_defense")) if "bonus_defense" in spider else 0
	var b_crit: float = float(spider.get("bonus_crit")) if "bonus_crit" in spider else 0.0

	# Calculate totals
	var total_hp := base_hp + spider.bonus_health
	var total_str := base_str + spider.bonus_strength
	var total_spd := base_spd + spider.bonus_speed
	var total_def := base_def + b_def
	var total_crit := base_crit + b_crit

	# Build display string
	var text_content := "[ %s ]\n" % spider.get_display_name()
	text_content += "HP: %d (%+d)\n" % [total_hp, spider.bonus_health]
	text_content += "STR: %d (%+d)\n" % [total_str, spider.bonus_strength]
	text_content += "SPD: %d (%+d)\n" % [total_spd, spider.bonus_speed]
	text_content += "DEF: %d (%+d)\n" % [total_def, b_def]
	text_content += "CRIT: %.0f%% (%+.0f%%)" % [total_crit, b_crit]

	label.text = text_content
	panel.show()
	
	# Force Godot to calculate container dimensions immediately
	panel.reset_size()
	
	# Clamp position so it stays inside viewport bounds
	var target_pos := pos + Vector2(15, 15)
	var viewport_size := get_viewport().get_visible_rect().size
	var panel_size := panel.size

	# Push above mouse if overflowing bottom edge
	if target_pos.y + panel_size.y > viewport_size.y:
		target_pos.y = pos.y - panel_size.y - 10

	# Push to left of mouse if overflowing right edge
	if target_pos.x + panel_size.x > viewport_size.x:
		target_pos.x = pos.x - panel_size.x - 10

	panel.global_position = target_pos

func hide_tooltip() -> void:
	panel.hide()