extends Node

signal item_added(item_id: String, amount: int)
signal item_removed(item_id: String, amount: int)
signal equipment_changed(slot: String, item: Dictionary)
signal gold_changed(new_amount: int)

var item_quantities: Dictionary = {}
var item_definitions: Dictionary = {}
var gold: int = 0

var equipment: Dictionary = {
	GameConstants.SLOT_WEAPON: null,
	GameConstants.SLOT_ARMOR: null,
	GameConstants.SLOT_ACCESSORY: null
}

func add_item(item: Dictionary, amount: int = 1) -> bool:
	var item_id: String = _get_item_id(item)
	
	if not item_definitions.has(item_id):
		item_definitions[item_id] = item
	
	if not item_quantities.has(item_id) and item_quantities.size() >= GameConstants.MAX_UNIQUE_ITEMS:
		return false
	
	var current_qty: int = item_quantities.get(item_id, 0)
	var new_qty: int = min(current_qty + amount, GameConstants.MAX_STACK_SIZE)
	item_quantities[item_id] = new_qty
	
	item_added.emit(item_id, amount)
	return true

func remove_item(item: Dictionary, amount: int = 1) -> bool:
	return remove_item_by_id(_get_item_id(item), amount)

func remove_item_by_id(item_id: String, amount: int = 1) -> bool:
	if not item_quantities.has(item_id):
		return false
	
	var current_qty: int = item_quantities[item_id]
	if current_qty < amount:
		return false
	
	var new_qty: int = current_qty - amount
	if new_qty <= 0:
		item_quantities.erase(item_id)
		item_definitions.erase(item_id)
	else:
		item_quantities[item_id] = new_qty
	
	item_removed.emit(item_id, amount)
	return true

func has_item(item: Dictionary) -> bool:
	return item_quantities.has(_get_item_id(item))

func has_item_id(item_id: String) -> bool:
	return item_quantities.has(item_id)

func get_item_count(item: Dictionary) -> int:
	return item_quantities.get(_get_item_id(item), 0)

func get_item_count_by_id(item_id: String) -> int:
	return item_quantities.get(item_id, 0)

func get_item_data(item_id: String) -> Dictionary:
	return item_definitions.get(item_id, {})

func get_all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item_id in item_quantities:
		var item_data: Dictionary = item_definitions.get(item_id, {}).duplicate()
		item_data["item_id"] = item_id
		item_data["quantity"] = item_quantities[item_id]
		result.append(item_data)
	return result

func _get_item_id(item: Dictionary) -> String:
	return item.get("item_id", item.get("item_name", "unknown"))

func equip_item(item: Dictionary) -> bool:
	var slot: int = item.get("equipment_slot", 0)
	if slot == 0:
		return false
	
	if equipment[slot]:
		unequip_item(slot)
	
	equipment[slot] = item
	remove_item(item, 1)
	
	equipment_changed.emit(get_slot_name(slot), item)
	return true

func unequip_item(slot: int) -> Dictionary:
	var item = equipment[slot]
	if item:
		equipment[slot] = null
		add_item(item, 1)
		equipment_changed.emit(get_slot_name(slot), {})
	return item

func get_equipped_item(slot: int) -> Dictionary:
	var item = equipment.get(slot)
	return item if item is Dictionary else {}

func get_total_attack() -> int:
	var total: int = 0
	for item in equipment.values():
		if item is Dictionary:
			total += item.get("attack", 0)
	return total

func get_total_defense() -> int:
	var total: int = 0
	for item in equipment.values():
		if item is Dictionary:
			total += item.get("defense", 0)
	return total

func add_gold(amount: int) -> void:
	gold += amount
	gold_changed.emit(gold)

func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		gold_changed.emit(gold)
		return true
	return false

func get_slot_name(slot: int) -> String:
	match slot:
		GameConstants.SLOT_WEAPON:
			return "weapon"
		GameConstants.SLOT_ARMOR:
			return "armor"
		GameConstants.SLOT_ACCESSORY:
			return "accessory"
	return ""

func get_save_data() -> Dictionary:
	return {
		"item_quantities": item_quantities.duplicate(),
		"item_definitions": item_definitions.duplicate(true),
		"equipment": equipment.duplicate(true),
		"gold": gold
	}

func load_save_data(data: Dictionary) -> void:
	item_quantities.clear()
	item_definitions.clear()
	gold = data.get("gold", 0)
	
	if data.has("item_quantities"):
		item_quantities = data.item_quantities.duplicate()
	
	if data.has("item_definitions"):
		item_definitions = data.item_definitions.duplicate(true)
	
	if data.has("equipment"):
		for slot_key in data.equipment:
			equipment[int(slot_key)] = data.equipment[slot_key]
