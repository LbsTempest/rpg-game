extends Node

var _items: Dictionary = {}
var _skills: Dictionary = {}
var _quests: Dictionary = {}
var _shops: Dictionary = {}
var _story_segments: Dictionary = {}
var _maps: Dictionary = {}
var _player_defaults: Dictionary = {}

func _ready() -> void:
	reload()

func reload() -> void:
	var payload := ContentLoader.new().load_content()
	_items = payload.get("items", {})
	_skills = payload.get("skills", {})
	_quests = payload.get("quests", {})
	_shops = payload.get("shops", {})
	_story_segments = payload.get("story", {})
	_maps = payload.get("maps", {})
	_player_defaults = payload.get("player_defaults", {})

func get_all_items() -> Dictionary:
	return _items.duplicate(true)

func get_item_definition(item_id: String) -> Dictionary:
	return _items.get(item_id, {}).duplicate(true)

func has_item(item_id: String) -> bool:
	return _items.has(item_id)

func get_all_skills() -> Dictionary:
	return _skills.duplicate(true)

func get_skill_definition(skill_id: String) -> Dictionary:
	return _skills.get(skill_id, {}).duplicate(true)

func has_skill(skill_id: String) -> bool:
	return _skills.has(skill_id)

func get_all_quests() -> Dictionary:
	return _quests.duplicate(true)

func get_quest_definition(quest_id: String) -> Dictionary:
	return _quests.get(quest_id, {}).duplicate(true)

func has_quest(quest_id: String) -> bool:
	return _quests.has(quest_id)

func get_all_shops() -> Dictionary:
	return _shops.duplicate(true)

func get_shop_definition(shop_id: String) -> Dictionary:
	return _shops.get(shop_id, {}).duplicate(true)

func has_shop(shop_id: String) -> bool:
	return _shops.has(shop_id)

func get_all_story_segments() -> Dictionary:
	return _story_segments.duplicate(true)

func get_story_segment(segment_id: String) -> Dictionary:
	return _story_segments.get(segment_id, {}).duplicate(true)

func get_all_maps() -> Dictionary:
	return _maps.duplicate(true)

func get_map_definition(map_id: String) -> Dictionary:
	return _maps.get(map_id, {}).duplicate(true)

func get_player_defaults() -> Dictionary:
	return _player_defaults.duplicate(true)

func get_starting_skill_ids() -> Array[String]:
	var result: Array[String] = []
	for skill_id in _player_defaults.get("starting_skills", []):
		if skill_id is String:
			result.append(skill_id)
	return result

func get_starting_gold() -> int:
	return _player_defaults.get("starting_gold", GameConstants.PLAYER_START_GOLD)

func get_starting_item_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _player_defaults.get("starting_items", []):
		if entry is Dictionary:
			result.append(entry.duplicate(true))
	return result
