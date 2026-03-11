class_name CharacterState
extends RefCounted

var position: Vector2 = Vector2.ZERO
var current_map: String = "world"
var max_health: int = GameConstants.PLAYER_START_HEALTH
var max_mana: int = GameConstants.PLAYER_START_MANA
var current_health: int = GameConstants.PLAYER_START_HEALTH
var current_mana: int = GameConstants.PLAYER_START_MANA
var attack: int = GameConstants.PLAYER_START_ATTACK
var defense: int = GameConstants.PLAYER_START_DEFENSE
var level: int = GameConstants.PLAYER_START_LEVEL
var experience: int = 0
var learned_skills: Array[String] = []
var skill_cooldowns: Dictionary = {}
var is_defending: bool = false

func reset() -> void:
	position = Vector2.ZERO
	current_map = "world"
	max_health = GameConstants.PLAYER_START_HEALTH
	max_mana = GameConstants.PLAYER_START_MANA
	current_health = max_health
	current_mana = max_mana
	attack = GameConstants.PLAYER_START_ATTACK
	defense = GameConstants.PLAYER_START_DEFENSE
	level = GameConstants.PLAYER_START_LEVEL
	experience = 0
	learned_skills.clear()
	skill_cooldowns.clear()
	is_defending = false

func apply_defaults(defaults: Dictionary) -> void:
	reset()
	if defaults.has("position"):
		var raw_position = defaults["position"]
		if raw_position is Vector2:
			position = raw_position

func to_save_data() -> Dictionary:
	return {
		"position": {"x": position.x, "y": position.y},
		"current_map": current_map,
		"max_health": max_health,
		"max_mana": max_mana,
		"current_health": current_health,
		"current_mana": current_mana,
		"attack": attack,
		"defense": defense,
		"level": level,
		"experience": experience
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("position"):
		position = Vector2(data.position.x, data.position.y)

	var properties := [
		"current_map",
		"max_health",
		"max_mana",
		"current_health",
		"current_mana",
		"attack",
		"defense",
		"level",
		"experience"
	]
	for prop in properties:
		if data.has(prop):
			set(prop, data[prop])
