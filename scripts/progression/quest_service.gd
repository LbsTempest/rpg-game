extends Node

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal quest_rewarded(quest_id: String)

var _quest_definitions: Dictionary = {}

func _ready() -> void:
	_reload_definitions()

func _state():
	return Session.run_state.quest

func _reload_definitions() -> void:
	_quest_definitions = ContentDB.get_all_quests()

func reset_state() -> void:
	_state().reset()

func can_start_quest(quest_id: String) -> bool:
	if not _quest_definitions.has(quest_id):
		return false

	if _state().active_quests.has(quest_id):
		return false
	if quest_id in _state().completed_quests:
		return false
	if quest_id in _state().rewarded_quests:
		return false

	var quest_def: Dictionary = _quest_definitions[quest_id]
	for prereq in quest_def.get("prerequisites", []):
		if not (prereq is String):
			continue
		if not String(prereq) in _state().rewarded_quests:
			return false
	return true

func get_quest(quest_id: String) -> Dictionary:
	if _state().active_quests.has(quest_id):
		return _state().active_quests[quest_id].duplicate(true)
	return _quest_definitions.get(quest_id, {}).duplicate(true)

func get_quest_status(quest_id: String) -> String:
	if _state().active_quests.has(quest_id):
		return "active"
	if quest_id in _state().completed_quests:
		return "completed"
	if quest_id in _state().rewarded_quests:
		return "rewarded"
	return "inactive"

func accept_quest(quest_id: String, source_id: String = "") -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if quest_id.is_empty():
		result.message = "missing_quest_id"
		return result
	if not can_start_quest(quest_id):
		result.message = "quest_start_failed"
		return result

	var quest_entry: Dictionary = _quest_definitions[quest_id].duplicate(true)
	quest_entry["status"] = "active"
	_state().active_quests[quest_id] = quest_entry

	result.success = true
	result.message = "quest_started"
	result.data = {"quest_id": quest_id, "source_id": source_id}

	quest_started.emit(quest_id)
	GameEvents.emit_domain_event("quest_started", {"quest_id": quest_id})
	GameEvents.emit_domain_event("quest_accepted_from_source", result.data)
	return result

func turn_in_quest(quest_id: String, source_id: String = "") -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if quest_id.is_empty():
		result.message = "missing_quest_id"
		return result
	if not quest_id in _state().completed_quests:
		result.message = "quest_reward_failed"
		return result

	var quest_definition: Dictionary = _quest_definitions.get(quest_id, {})
	if quest_definition.is_empty():
		result.message = "quest_definition_missing"
		return result

	RewardService.grant_quest_rewards(quest_definition)
	_state().completed_quests.erase(quest_id)
	_state().rewarded_quests.append(quest_id)

	result.success = true
	result.message = "quest_rewarded"
	result.data = {"quest_id": quest_id, "source_id": source_id}

	quest_rewarded.emit(quest_id)
	GameEvents.emit_domain_event("quest_rewarded", {"quest_id": quest_id})
	GameEvents.emit_domain_event("quest_turned_in_at_source", result.data)
	return result

func update_progress(objective_type: String, target_id: String, amount: int = 1) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if objective_type.is_empty() or target_id.is_empty():
		result.message = "invalid_payload"
		return result

	for quest_id in _state().active_quests.keys():
		_update_single_quest(String(quest_id), objective_type, target_id, amount)

	result.success = true
	result.message = "quest_progress_updated"
	result.data = {"objective_type": objective_type, "target_id": target_id, "amount": amount}
	return result

func get_journal_view_data() -> Dictionary:
	var active_entries: Array[Dictionary] = []
	for quest_id in _state().active_quests:
		var quest_data: Dictionary = _state().active_quests[quest_id].duplicate(true)
		quest_data["quest_id"] = quest_id
		quest_data["status"] = "active"
		active_entries.append(quest_data)

	var completed_entries: Array[Dictionary] = []
	for quest_id in _state().completed_quests:
		var quest_data := get_quest(quest_id).duplicate(true)
		quest_data["quest_id"] = quest_id
		quest_data["status"] = "completed"
		completed_entries.append(quest_data)

	var rewarded_entries: Array[Dictionary] = []
	for quest_id in _state().rewarded_quests:
		var quest_data := get_quest(quest_id).duplicate(true)
		quest_data["quest_id"] = quest_id
		quest_data["status"] = "rewarded"
		rewarded_entries.append(quest_data)

	return {
		"active": active_entries,
		"completed": completed_entries,
		"rewarded": rewarded_entries
	}

func _update_single_quest(quest_id: String, objective_type: String, target_id: String, amount: int) -> void:
	if not _state().active_quests.has(quest_id):
		return

	var quest_entry: Dictionary = _state().active_quests[quest_id]
	var objectives: Array = quest_entry.get("objectives", [])
	var updated: bool = false

	for i in range(objectives.size()):
		var objective = objectives[i]
		if not objective is Dictionary:
			continue
		if String(objective.get("type", "")) != objective_type:
			continue
		if String(objective.get("target", "")) != target_id:
			continue

		var current: int = int(objective.get("current", 0))
		var required: int = int(objective.get("required", 0))
		if current >= required:
			continue

		objective["current"] = min(current + amount, required)
		objective["description"] = _format_objective_description(objective)
		objectives[i] = objective
		updated = true

		quest_updated.emit(quest_id, i)
		GameEvents.emit_domain_event(
			"quest_progress_updated",
			{
				"quest_id": quest_id,
				"objective_index": i,
				"type": objective_type,
				"target": target_id,
				"amount": amount
			}
		)
		break

	quest_entry["objectives"] = objectives
	_state().active_quests[quest_id] = quest_entry
	if updated and _is_quest_completed(quest_entry):
		_complete_quest(quest_id)

func _is_quest_completed(quest_entry: Dictionary) -> bool:
	for objective in quest_entry.get("objectives", []):
		if not objective is Dictionary:
			continue
		if int(objective.get("current", 0)) < int(objective.get("required", 0)):
			return false
	return true

func _complete_quest(quest_id: String) -> void:
	if not _state().active_quests.has(quest_id):
		return

	var quest_entry: Dictionary = _state().active_quests[quest_id]
	quest_entry["status"] = "completed"
	_state().active_quests.erase(quest_id)
	_state().completed_quests.append(quest_id)

	quest_completed.emit(quest_id)
	GameEvents.emit_domain_event("quest_completed", {"quest_id": quest_id})

func _format_objective_description(objective: Dictionary) -> String:
	var text: String = String(objective.get("description", ""))
	if text.is_empty():
		match String(objective.get("type", "")):
			GameConstants.OBJECTIVE_KILL:
				text = "击败 %s" % String(objective.get("target", ""))
			GameConstants.OBJECTIVE_COLLECT:
				text = "收集 %s" % String(objective.get("target", ""))
			GameConstants.OBJECTIVE_TALK:
				text = "与 %s 对话" % String(objective.get("target", ""))
			GameConstants.OBJECTIVE_LOCATION:
				text = "到达 %s" % String(objective.get("target", ""))
			_:
				text = "%s %s" % [String(objective.get("type", "")), String(objective.get("target", ""))]
	return "%s (%d/%d)" % [text, int(objective.get("current", 0)), int(objective.get("required", 0))]
