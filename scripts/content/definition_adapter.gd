class_name DefinitionAdapter
extends RefCounted

static func normalize_item_definition(item_id: String, raw: Dictionary) -> Dictionary:
	var effects: Dictionary = raw.get("effects", {})
	var item_type: int = _normalize_item_type(raw.get("item_type", raw.get("type", "")))
	var equipment_slot: int = _normalize_equipment_slot(raw.get("equipment_slot", 0))
	var display_name: String = raw.get("display_name", raw.get("item_name", item_id))
	var attack: int = raw.get("attack", effects.get("attack", 0))
	var defense: int = raw.get("defense", effects.get("defense", 0))
	var heal_amount: int = raw.get("heal_amount", effects.get("heal_amount", 0))
	var restore_mana_amount: int = raw.get(
		"restore_mana_amount",
		raw.get("restore_mana", effects.get("restore_mana_amount", effects.get("restore_mana", 0)))
	)

	return {
		"item_id": item_id,
		"display_name": display_name,
		"item_name": display_name,
		"description": raw.get("description", ""),
		"icon_path": raw.get("icon_path", ""),
		"item_type": item_type,
		"type": _item_type_name(item_type),
		"equipment_slot": equipment_slot,
		"price": raw.get("price", 0),
		"sell_price": raw.get("sell_price", int(raw.get("price", 0) * GameConstants.SHOP_SELL_RATE)),
		"stackable": raw.get("stackable", item_type == GameConstants.ITEM_TYPE_CONSUMABLE),
		"max_stack": raw.get("max_stack", GameConstants.MAX_STACK_SIZE),
		"attack": attack,
		"defense": defense,
		"heal_amount": heal_amount,
		"restore_mana_amount": restore_mana_amount,
		"effects": {
			"attack": attack,
			"defense": defense,
			"heal_amount": heal_amount,
			"restore_mana_amount": restore_mana_amount
		}
	}

static func normalize_skill_definition(skill_id: String, raw: Dictionary) -> Dictionary:
	var display_name: String = raw.get("display_name", raw.get("name", skill_id))

	return {
		"skill_id": skill_id,
		"display_name": display_name,
		"name": display_name,
		"description": raw.get("description", ""),
		"mana_cost": raw.get("mana_cost", 0),
		"base_damage": raw.get("base_damage", 0),
		"base_heal": raw.get("base_heal", raw.get("heal", 0)),
		"target_type": raw.get("target_type", raw.get("target", "enemy")),
		"target": raw.get("target", raw.get("target_type", "enemy")),
		"cooldown": raw.get("cooldown", 0)
	}

static func normalize_quest_definition(quest_id: String, raw: Dictionary) -> Dictionary:
	var objectives: Array = []
	for raw_objective in raw.get("objectives", []):
		var objective_type: String = raw_objective.get("objective_type", raw_objective.get("type", ""))
		var target_id: String = raw_objective.get("target_id", raw_objective.get("target", ""))
		objectives.append({
			"objective_type": objective_type,
			"type": objective_type,
			"target_id": target_id,
			"target": target_id,
			"required": raw_objective.get("required", 0),
			"current": raw_objective.get("current", 0),
			"description": raw_objective.get("description", "")
		})

	var reward_items: Array = []
	for reward in raw.get("rewards", {}).get("items", []):
		var reward_item_id: String = reward.get("item_id", reward.get("id", ""))
		reward_items.append({
			"item_id": reward_item_id,
			"id": reward_item_id,
			"quantity": reward.get("quantity", 1)
		})

	var rewards: Dictionary = {
		"experience": raw.get("rewards", {}).get("experience", 0),
		"gold": raw.get("rewards", {}).get("gold", 0),
		"items": reward_items
	}

	var display_name: String = raw.get("display_name", raw.get("name", quest_id))
	var quest_type: String = raw.get("quest_type", raw.get("type", GameConstants.QUEST_TYPE_SIDE))

	return {
		"quest_id": quest_id,
		"id": quest_id,
		"display_name": display_name,
		"name": display_name,
		"description": raw.get("description", ""),
		"quest_type": quest_type,
		"type": quest_type,
		"status": raw.get("status", "inactive"),
		"objectives": objectives,
		"rewards": rewards,
		"prerequisites": raw.get("prerequisites", []).duplicate(),
		"offer_sources": raw.get("offer_sources", _single_value_array(raw.get("giver_npc", ""))),
		"turn_in_sources": raw.get("turn_in_sources", []).duplicate()
	}

static func normalize_shop_definition(shop_id: String, raw: Dictionary) -> Dictionary:
	var entries: Array = []
	for entry in raw.get("items", []):
		entries.append({
			"item_id": entry.get("item_id", ""),
			"base_quantity": entry.get("base_quantity", 0),
			"infinite": entry.get("infinite", false)
		})

	var display_name: String = raw.get("display_name", raw.get("name", shop_id))

	return {
		"shop_id": shop_id,
		"id": shop_id,
		"display_name": display_name,
		"name": display_name,
		"items": entries,
		"buy_rate": raw.get("buy_rate", GameConstants.SHOP_BUY_RATE),
		"sell_rate": raw.get("sell_rate", GameConstants.SHOP_SELL_RATE)
	}

static func _normalize_item_type(value) -> int:
	if value is int:
		return value

	match String(value):
		"consumable":
			return GameConstants.ITEM_TYPE_CONSUMABLE
		"equipment":
			return GameConstants.ITEM_TYPE_EQUIPMENT
		"key":
			return GameConstants.ITEM_TYPE_KEY
		_:
			return GameConstants.ITEM_TYPE_CONSUMABLE

static func _item_type_name(value: int) -> String:
	match value:
		GameConstants.ITEM_TYPE_EQUIPMENT:
			return "equipment"
		GameConstants.ITEM_TYPE_KEY:
			return "key"
		_:
			return "consumable"

static func _normalize_equipment_slot(value) -> int:
	if value is int:
		return value

	match String(value):
		"weapon":
			return GameConstants.SLOT_WEAPON
		"armor":
			return GameConstants.SLOT_ARMOR
		"accessory":
			return GameConstants.SLOT_ACCESSORY
		_:
			return 0

static func _single_value_array(value: String) -> Array:
	if value.is_empty():
		return []
	return [value]
