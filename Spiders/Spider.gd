extends Resource
class_name Spider

## Runtime battle data for one spider in a fight. Build these from a
## SpiderSpecies via Spider.from_species() rather than constructing
## by hand — that keeps species data as the single source of truth.

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

static func from_species(species: SpiderSpecies) -> Spider:
	var s := Spider.new()
	s.spider_name = species.species_name
	s.max_health = int(species.health) if species.health > 0 else 100
	s.speed = int(species.speed) if species.speed > 0 else 5
	s.strength = int(species.strength) if species.strength > 0 else 5
	s.crit_chance = int(species.crit_chance) if species.crit_chance > 0 else 10
	s.max_shield = int(species.shield)
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