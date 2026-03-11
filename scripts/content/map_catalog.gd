class_name MapCatalog
extends RefCounted

const SOURCES := [
	"res://resources/data/maps/default_maps.gd"
]

func load_definitions() -> Dictionary:
	var definitions: Dictionary = {}

	for source_path in SOURCES:
		var source = load(source_path).new()
		for map_id in source.definitions:
			definitions[map_id] = source.definitions[map_id].duplicate(true)

	return definitions
