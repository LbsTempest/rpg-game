class_name SkillCatalog
extends RefCounted

const SOURCES := [
	"res://resources/data/skills/default_skills.gd"
]

func load_definitions() -> Dictionary:
	var definitions: Dictionary = {}

	for source_path in SOURCES:
		var source = load(source_path).new()
		for skill_id in source.definitions:
			definitions[skill_id] = DefinitionAdapter.normalize_skill_definition(skill_id, source.definitions[skill_id])

	return definitions
