extends Resource
class_name CaughtSpider

@export var species: SpiderSpecies
@export var caught_time: String = ""
@export var nickname: String = ""

@export var bonus_health: int = 0
@export var bonus_strength: int = 0
@export var bonus_speed: int = 0
@export var bonus_defense: int = 0
@export var bonus_crit: float = 0.0
@export var bonus_evasion: float = 0.0 # NEW: Evasion Bonus (%)

func _init(p_species: SpiderSpecies = null, p_time: String = "", p_nickname: String = "") -> void:
	species = p_species
	caught_time = p_time
	nickname = p_nickname

	if species:
		# Individual stat rolls
		bonus_health = randi_range(-2, 10)
		bonus_strength = randi_range(-1, 3)
		bonus_speed = randi_range(-1, 3)
		bonus_defense = randi_range(0, 2)
		bonus_crit = randf_range(0.0, 5.0)
		bonus_evasion = randf_range(0.0, 5.0) # Rolls +0% to +5% bonus dodge chance

func get_display_name() -> String:
	if nickname != "":
		return nickname
	return species.species_name if species else "Unnamed Spider"