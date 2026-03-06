extends Node

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal quest_rewarded(quest_id: String)

var quest_database: Dictionary = {}
var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var rewarded_quests: Array[String] = []

var _items_data: Node = null

func _ready() -> void:
	_initialize_quest_database()

func _initialize_quest_database() -> void:
	var quests_data = load("res://resources/data/quests_data.gd").new()
	quest_database = quests_data.quest_database.duplicate(true)
	quests_data.free()

func can_start_quest(quest_id: String) -> bool:
	if not quest_database.has(quest_id):
		return false
	if active_quests.has(quest_id) or completed_quests.has(quest_id) or rewarded_quests.has(quest_id):
		return false
	
	var quest_def = quest_database[quest_id]
	for prereq in quest_def.get("prerequisites", []):
		if not rewarded_quests.has(prereq):
			return false
	return true

func start_quest(quest_id: String) -> bool:
	if not can_start_quest(quest_id):
		return false
	
	var quest_def = quest_database[quest_id].duplicate(true)
	quest_def["status"] = "active"
	active_quests[quest_id] = quest_def
	
	quest_started.emit(quest_id)
	return true

func update_quest(quest_id: String, objective_type: String, target: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	var updated = false
	
	for i in range(quest["objectives"].size()):
		var obj = quest["objectives"][i]
		if obj["type"] == objective_type and obj["target"] == target:
			if obj["current"] < obj["required"]:
				obj["current"] = min(obj["current"] + amount, obj["required"])
				obj["description"] = _generate_objective_description(obj)
				updated = true
				quest_updated.emit(quest_id, i)
				break
	
	if updated and _is_quest_complete(quest):
		_complete_quest(quest_id)

func update_all_quests(objective_type: String, target: String, amount: int = 1) -> void:
	for quest_id in active_quests.keys():
		update_quest(quest_id, objective_type, target, amount)

func _is_quest_complete(quest: Dictionary) -> bool:
	for obj in quest["objectives"]:
		if obj["current"] < obj["required"]:
			return false
	return true

func _complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	quest["status"] = "completed"
	
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	
	quest_completed.emit(quest_id)

func reward_quest(quest_id: String) -> bool:
	if not completed_quests.has(quest_id):
		return false
	
	var quest_def = quest_database[quest_id]
	var rewards = quest_def.get("rewards", {})
	
	if rewards.has("experience") and rewards["experience"] > 0:
		var player = Utils.get_group_node("player")
		if player and player.has_method("add_experience"):
			player.add_experience(rewards["experience"])
	
	if rewards.has("gold") and rewards["gold"] > 0:
		InventoryManager.add_gold(rewards["gold"])
	
	if rewards.has("items"):
		for item_reward in rewards["items"]:
			var item_data = _get_item_data_by_id(item_reward["id"])
			if item_data:
				InventoryManager.add_item(item_data, item_reward["quantity"])
	
	completed_quests.erase(quest_id)
	rewarded_quests.append(quest_id)
	
	quest_rewarded.emit(quest_id)
	return true

func _get_item_data_by_id(item_id: String) -> Dictionary:
	if _items_data == null:
		_items_data = load("res://resources/data/items_data.gd").new()
	
	if _items_data.items_database.has(item_id):
		return _items_data.items_database[item_id].duplicate()
	
	return {}

func _generate_objective_description(obj: Dictionary) -> String:
	var desc = obj.get("description", "")
	if desc.is_empty():
		match obj["type"]:
			GameConstants.OBJECTIVE_KILL:
				desc = "击败 %s" % obj["target"]
			GameConstants.OBJECTIVE_COLLECT:
				desc = "收集 %s" % obj["target"]
			GameConstants.OBJECTIVE_TALK:
				desc = "与 %s 对话" % obj["target"]
			GameConstants.OBJECTIVE_LOCATION:
				desc = "到达 %s" % obj["target"]
	
	return "%s (%d/%d)" % [desc, obj["current"], obj["required"]]

func get_active_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in active_quests:
		result.append(active_quests[quest_id])
	return result

func get_quest(quest_id: String) -> Dictionary:
	if active_quests.has(quest_id):
		return active_quests[quest_id]
	if quest_database.has(quest_id):
		return quest_database[quest_id]
	return {}

func get_quest_status(quest_id: String) -> String:
	if active_quests.has(quest_id):
		return "active"
	if completed_quests.has(quest_id):
		return "completed"
	if rewarded_quests.has(quest_id):
		return "rewarded"
	return "inactive"

func get_save_data() -> Dictionary:
	return {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(),
		"rewarded_quests": rewarded_quests.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	active_quests.clear()
	completed_quests.clear()
	rewarded_quests.clear()
	
	if data.has("active_quests"):
		active_quests = data["active_quests"].duplicate(true)
	
	if data.has("completed_quests"):
		for quest_id in data["completed_quests"]:
			if quest_id is String:
				completed_quests.append(quest_id)
	
	if data.has("rewarded_quests"):
		for quest_id in data["rewarded_quests"]:
			if quest_id is String:
				rewarded_quests.append(quest_id)

func add_quest_definition(quest_def: Dictionary) -> void:
	if quest_def.has("id"):
		quest_database[quest_def["id"]] = quest_def.duplicate(true)

func reset_all_quests() -> void:
	active_quests.clear()
	completed_quests.clear()
	rewarded_quests.clear()
