class_name ItemCatalog
extends RefCounted

const SOURCES := [
	"res://resources/data/items/default_items.gd"
]

func load_definitions() -> Dictionary:
	var definitions: Dictionary = {}

	for source_path in SOURCES:
		var source = load(source_path).new()
		for item_id in source.definitions:
			definitions[item_id] = DefinitionAdapter.normalize_item_definition(item_id, source.definitions[item_id])

	return definitions
