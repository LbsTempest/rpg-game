class_name QuestCatalog
extends RefCounted

const SOURCES := [
	"res://resources/data/quests/default_quests.gd"
]

func load_definitions() -> Dictionary:
	var definitions: Dictionary = {}

	for source_path in SOURCES:
		var source = load(source_path).new()
		for quest_id in source.definitions:
			definitions[quest_id] = DefinitionAdapter.normalize_quest_definition(quest_id, source.definitions[quest_id])

	return definitions
