class_name InventoryState
extends RefCounted

var item_quantities: Dictionary = {}
var item_definitions: Dictionary = {}
var gold: int = 0
var equipment: Dictionary = {
	GameConstants.SLOT_WEAPON: null,
	GameConstants.SLOT_ARMOR: null,
	GameConstants.SLOT_ACCESSORY: null
}

func reset() -> void:
	item_quantities.clear()
	item_definitions.clear()
	gold = 0
	equipment = {
		GameConstants.SLOT_WEAPON: null,
		GameConstants.SLOT_ARMOR: null,
		GameConstants.SLOT_ACCESSORY: null
	}

func to_save_data() -> Dictionary:
	return {
		"item_quantities": item_quantities.duplicate(),
		"item_definitions": item_definitions.duplicate(true),
		"equipment": equipment.duplicate(true),
		"gold": gold
	}

func load_save_data(data: Dictionary) -> void:
	reset()
	gold = data.get("gold", 0)

	if data.has("item_quantities"):
		item_quantities = data.item_quantities.duplicate()

	if data.has("item_definitions"):
		item_definitions = data.item_definitions.duplicate(true)

	if data.has("equipment"):
		for slot_key in data.equipment:
			equipment[int(slot_key)] = data.equipment[slot_key]
