extends Resource
class_name Spider

## Runtime battle data for one spider in a fight. Build these from a
## SpiderSpecies or CaughtSpider via Spider.from_species().

@export var spider_name: String = "Unnamed Spider"
@export var max_health: int = 100
@export var speed: int = 5
@export var strength: int = 5
@export var crit_chance: int = 10
@export var max_shield: int = 0

var current_health: int
var current_shield: int
var gauge: float = 0.0

const CRIT_MULTIPLIER := 1.6
const GAUGE_MAX := 100.0
const SPEED_TO_GAUGE_RATE := 1.2

static func from_species(species_or_caught) -> Spider:
	var s := Spider.new()
	var base_species: SpiderSpecies
	var caught: CaughtSpider = null

	if species_or_caught is CaughtSpider:
		caught = species_or_caught
		base_species = caught.species
	elif species_or_caught is SpiderSpecies:
		base_species = species_or_caught

	if not base_species:
		return s

	s.spider_name = base_species.species_name
	
	# Extract individual bonuses if passing a CaughtSpider
	var b_hp := caught.bonus_health if caught else 0
	var b_str := caught.bonus_strength if caught else 0
	var b_spd := caught.bonus_speed if caught else 0

	s.max_health = max(10, (int(base_species.health) if base_species.health > 0 else 100) + b_hp)
	s.speed = max(1, (int(base_species.speed) if base_species.speed > 0 else 5) + b_spd)
	s.strength = max(1, (int(base_species.strength) if base_species.strength > 0 else 5) + b_str)
	s.crit_chance = int(base_species.crit_chance) if base_species.crit_chance > 0 else 10
	s.max_shield = int(base_species.shield)
	
	return s

func reset_for_battle() -> void:
	current_health = max_health
	current_shield = max_shield
	gauge = 0.0

func tick_gauge() -> bool:
	gauge = min(GAUGE_MAX, gauge + speed * SPEED_TO_GAUGE_RATE)
	if gauge >= GAUGE_MAX:
		gauge = 0.0
		return true
	return false

func roll_attack_damage() -> Dictionary:
	var is_crit := randf() * 100.0 < crit_chance
	var dmg := int(round(strength * (CRIT_MULTIPLIER if is_crit else 1.0)))
	return {"damage": dmg, "is_crit": is_crit}

func take_damage(raw_damage: int) -> Dictionary:
	var absorbed := 0
	var shield_broke := false
	var remaining := raw_damage

	if current_shield > 0:
		absorbed = min(current_shield, remaining)
		current_shield -= absorbed
		remaining -= absorbed
		if current_shield <= 0:
			shield_broke = true

	if remaining > 0:
		current_health = max(0, current_health - remaining)

	return {
		"absorbed": absorbed,
		"health_damage": remaining,
		"shield_broke": shield_broke,
		"shield_remaining": current_shield,
		"health_remaining": current_health,
	}

func is_defeated() -> bool:
	return current_health <= 0