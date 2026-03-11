class_name CombatantState
extends RefCounted

var combatant_id: String = ""
var display_name: String = ""
var faction: String = ""
var source_node: Node = null
var max_health: int = 1
var current_health: int = 1
var max_mana: int = 0
var current_mana: int = 0
var attack: int = 0
var defense: int = 0
var is_alive: bool = true
var is_defending: bool = false
var metadata: Dictionary = {}

static func from_node(combatant_id_val: String, faction_val: String, node: Node) -> CombatantState:
	var combatant := CombatantState.new()
	combatant.combatant_id = combatant_id_val
	combatant.faction = faction_val
	combatant.source_node = node
	combatant.metadata = _build_metadata(node, faction_val)
	combatant.sync_from_source()
	return combatant

func sync_from_source() -> void:
	if source_node == null:
		return

	display_name = _read_name()
	max_health = int(_read_value("max_health", 1))
	current_health = int(_read_value("current_health", max_health))
	max_mana = int(_read_value("max_mana", 0))
	current_mana = int(_read_value("current_mana", max_mana))
	attack = int(_read_value("attack", 0))
	defense = int(_read_value("defense", 0))
	is_defending = bool(_read_value("_is_defending", false))
	metadata["display_name"] = display_name
	metadata["faction"] = faction

	if "is_alive" in source_node:
		is_alive = bool(source_node.is_alive)
	else:
		is_alive = current_health > 0

func set_defending(enabled: bool) -> void:
	is_defending = enabled
	if source_node and source_node.has_method("set_defending"):
		source_node.set_defending(enabled)

func to_view_data() -> Dictionary:
	return {
		"combatant_id": combatant_id,
		"display_name": display_name,
		"faction": faction,
		"max_health": max_health,
		"current_health": current_health,
		"max_mana": max_mana,
		"current_mana": current_mana,
		"attack": attack,
		"defense": defense,
		"is_alive": is_alive,
		"is_defending": is_defending,
		"metadata": metadata.duplicate(true)
	}

func _read_name() -> String:
	if source_node == null:
		return combatant_id
	if "enemy_name" in source_node:
		return String(source_node.enemy_name)
	if "npc_name" in source_node:
		return String(source_node.npc_name)
	if "name" in source_node:
		return String(source_node.name)
	return combatant_id

func _read_value(property_name: String, fallback):
	if source_node == null:
		return fallback
	if property_name in source_node:
		return source_node.get(property_name)
	return fallback

static func _build_metadata(node: Node, faction_val: String) -> Dictionary:
	var data: Dictionary = {"faction": faction_val}
	if node == null:
		return data

	var scene_path: String = String(node.scene_file_path)
	if not scene_path.is_empty():
		data["scene_path"] = scene_path
		data["definition_id"] = scene_path.get_file().get_basename()

	if not data.has("definition_id") or String(data["definition_id"]).is_empty():
		var fallback_name := ""
		if "enemy_name" in node:
			fallback_name = String(node.enemy_name)
		elif "npc_name" in node:
			fallback_name = String(node.npc_name)
		else:
			fallback_name = String(node.name)
		data["definition_id"] = fallback_name.to_snake_case()

	return data
