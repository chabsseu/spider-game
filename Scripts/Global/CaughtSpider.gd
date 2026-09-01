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

func _init(p_species: SpiderSpecies = null, p_caught_time: String = "", p_nickname: String = "") -> void:
	species = p_species
	caught_time = p_caught_time
	nickname = p_nickname

	# Roll unique stat bonuses when a new spider is created
	if p_species:
		bonus_health = randi_range(-5, 15)
		bonus_strength = randi_range(-2, 3)
		bonus_speed = randi_range(-1, 2)

func get_display_name() -> String:
	if nickname != "":
		return nickname
	return species.species_name if species else "Unknown Spider"