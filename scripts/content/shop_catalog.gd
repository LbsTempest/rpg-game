class_name ShopCatalog
extends RefCounted

const SOURCES := [
	"res://resources/data/shops/default_shops.gd"
]

func load_definitions() -> Dictionary:
	var definitions: Dictionary = {}

	for source_path in SOURCES:
		var source = load(source_path).new()
		for shop_id in source.definitions:
			definitions[shop_id] = DefinitionAdapter.normalize_shop_definition(shop_id, source.definitions[shop_id])

	return definitions
