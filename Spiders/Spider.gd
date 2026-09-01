extends Resource
class_name Spider

## Runtime battle data for one spider in a fight. Build these from a
## SpiderSpecies or CaughtSpider via Spider.from_species().

@export var spider_name: String = "Unnamed Spider"
@export var max_health: int = 100
@export var speed: int = 5
@export var strength: int = 5
@export var crit_chance: float = 10.0 # Percentage (e.g., 10.0 = 10%)
@export var defense: int = 0          # Flat damage reduction (Baluti)
@export var evasion: float = 0.0      # Chance to dodge incoming hits (Iliwas %)
@export var max_shield: int = 0

var current_health: int
var current_shield: int
var gauge: float = 0.0

const CRIT_MULTIPLIER := 1.6
const GAUGE_MAX := 100.0
const SPEED_TO_GAUGE_RATE := 1.2

static func from_species(species_or_caught: Variant) -> Spider:
	var s := Spider.new()
	var base_species: SpiderSpecies = null
	var caught: CaughtSpider = null

	if species_or_caught is CaughtSpider:
		caught = species_or_caught as CaughtSpider
		base_species = caught.species
	elif species_or_caught is SpiderSpecies:
		base_species = species_or_caught as SpiderSpecies

	if not base_species:
		return s

	s.spider_name = base_species.species_name
	
	# Extract typed individual bonuses from CaughtSpider
	var b_hp: int = caught.bonus_health if caught else 0
	var b_str: int = caught.bonus_strength if caught else 0
	var b_spd: int = caught.bonus_speed if caught else 0
	
	# Explicitly typed fallback checks to prevent Variant inference errors
	var b_def: int = int(caught.get("bonus_defense")) if (caught and "bonus_defense" in caught) else 0
	var b_crit: float = float(caught.get("bonus_crit")) if (caught and "bonus_crit" in caught) else 0.0
	var b_eva: float = float(caught.get("bonus_evasion")) if (caught and "bonus_evasion" in caught) else 0.0

	# Calculate runtime stats
	s.max_health = max(10, (int(base_species.health) if base_species.health > 0 else 100) + b_hp)
	s.speed = max(1, (int(base_species.speed) if base_species.speed > 0 else 5) + b_spd)
	s.strength = max(1, (int(base_species.strength) if base_species.strength > 0 else 5) + b_str)
	s.crit_chance = max(0.0, (float(base_species.crit_chance) if base_species.crit_chance > 0.0 else 10.0) + b_crit)
	s.max_shield = int(base_species.shield)
	
	# Set defense and evasion
	var base_def: int = int(base_species.get("defense")) if "defense" in base_species else 0
	var base_eva: float = float(base_species.get("evasion")) if "evasion" in base_species else 0.0
	
	s.defense = max(0, base_def + b_def)
	s.evasion = max(0.0, base_eva + b_eva)
	
	return s

func reset_for_battle() -> void:
	current_health = max_health
	current_shield = max_shield
	gauge = 0.0

func tick_gauge() -> bool:
	gauge = min(GAUGE_MAX, gauge + float(speed) * SPEED_TO_GAUGE_RATE)
	if gauge >= GAUGE_MAX:
		gauge = 0.0
		return true
	return false

func roll_attack_damage() -> Dictionary:
	var is_crit: bool = (randf() * 100.0) < crit_chance
	var dmg: int = int(round(float(strength) * (CRIT_MULTIPLIER if is_crit else 1.0)))
	return {
		"damage": dmg, 
		"is_crit": is_crit
	}

func take_damage(raw_damage: int) -> Dictionary:
	# 1. Evasion Roll (Dodge)
	if (randf() * 100.0) < evasion:
		return {
			"dodged": true,
			"absorbed": 0,
			"health_damage": 0,
			"shield_broke": false,
			"shield_remaining": current_shield,
			"health_remaining": current_health,
		}

	# 2. Defense Mitigation (Flat reduction, minimum 1 damage)
	var mitigated_damage: int = max(1, raw_damage - defense)
	var absorbed: int = 0
	var shield_broke: bool = false
	var remaining: int = mitigated_damage

	# 3. Shield Calculations
	if current_shield > 0:
		absorbed = min(current_shield, remaining)
		current_shield -= absorbed
		remaining -= absorbed
		if current_shield <= 0:
			shield_broke = true

	# 4. Health Deduction
	if remaining > 0:
		current_health = max(0, current_health - remaining)

	return {
		"dodged": false,
		"absorbed": absorbed,
		"health_damage": remaining,
		"shield_broke": shield_broke,
		"shield_remaining": current_shield,
		"health_remaining": current_health,
	}

func is_defeated() -> bool:
	return current_health <= 0