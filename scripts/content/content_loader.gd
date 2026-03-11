class_name ContentLoader
extends RefCounted

func load_content() -> Dictionary:
	var player_defaults = load("res://resources/data/actors/player_defaults.gd").new()

	return {
		"items": ItemCatalog.new().load_definitions(),
		"skills": SkillCatalog.new().load_definitions(),
		"quests": QuestCatalog.new().load_definitions(),
		"shops": ShopCatalog.new().load_definitions(),
		"story": StoryCatalog.new().load_definitions(),
		"maps": MapCatalog.new().load_definitions(),
		"player_defaults": player_defaults.defaults.duplicate(true)
	}
