extends RefCounted
class_name CaughtSpider

## Represents one individual caught spider (not just its species type).
## Kept minimal for now — species identity + catch time. Extend later
## with a nickname, condition/feeding stats, etc. once those systems exist.

var species: SpiderSpecies
var caught_time: String # e.g. "19:42", from DayNightCycle.get_time_string()
var nickname: String = ""
func _init(p_species: SpiderSpecies, p_caught_time: String = "") -> void:
	species = p_species
	caught_time = p_caught_time

func get_display_name() -> String:
	if nickname != "":
		return nickname
	return species.species_name if species else "Unknown Spider"