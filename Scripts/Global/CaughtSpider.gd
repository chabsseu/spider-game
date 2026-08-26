extends RefCounted
class_name CaughtSpider

## Represents one individual caught spider (not just its species type).

var species: SpiderSpecies
var caught_time: String # e.g. "19:42", from DayNightCycle.get_time_string()
var nickname: String = ""

# Update _init to accept 3 parameters (with default empty values for flexibility)
func _init(p_species: SpiderSpecies = null, p_caught_time: String = "", p_nickname: String = "") -> void:
	species = p_species
	caught_time = p_caught_time
	nickname = p_nickname

func get_display_name() -> String:
	if nickname != "":
		return nickname
	return species.species_name if species else "Unknown Spider"