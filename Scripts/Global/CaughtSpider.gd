extends RefCounted
class_name CaughtSpider

## Represents one individual caught spider (not just its species type).

var species: SpiderSpecies
var caught_time: String # e.g. "19:42", from DayNightCycle.get_time_string()
var nickname: String = ""

# Individual Stat Modifiers (rolled on capture, stored permanently)
var bonus_health: int = 0
var bonus_strength: int = 0
var bonus_speed: int = 0
var bonus_crit_rate: float = 0.0 # e.g. 0.05 (+5%)
var bonus_defense: int = 0

func _init(p_species: SpiderSpecies, p_time: String = "", p_nickname: String = "") -> void:
	species = p_species
	caught_time = p_time
	nickname = p_nickname

	# Stat rolls
	bonus_health = randi_range(-2, 10)
	bonus_strength = randi_range(-1, 3)
	bonus_speed = randi_range(-1, 3)
	
	# NEW STAT ROLLS:
	bonus_defense = randi_range(0, 2)
	bonus_crit_rate = randf_range(0.0, 0.10) # 0% to +10% bonus crit
		

func get_display_name() -> String:
	if nickname != "":
		return nickname
	return species.species_name if species else "Unknown Spider"