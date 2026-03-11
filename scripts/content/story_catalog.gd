class_name StoryCatalog
extends RefCounted

const SOURCES := [
	"res://resources/data/story/default_story.gd"
]

func load_definitions() -> Dictionary:
	var definitions: Dictionary = {}

	for source_path in SOURCES:
		var source = load(source_path).new()
		for segment_id in source.definitions:
			definitions[segment_id] = source.definitions[segment_id].duplicate(true)

	return definitions
