class_name EncounterCatalog
extends RefCounted

const SOURCES := [
	"res://resources/data/encounters/default_encounters.gd"
]

func load_definitions() -> Dictionary:
	var definitions: Dictionary = {}

	for source_path in SOURCES:
		var source = load(source_path).new()
		for encounter_id in source.definitions:
			definitions[encounter_id] = source.definitions[encounter_id].duplicate(true)

	return definitions
