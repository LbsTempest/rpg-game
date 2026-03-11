extends Node

func accept_quest(quest_id: String, source_id: String = "") -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if quest_id.is_empty():
		result.message = "missing_quest_id"
		return result

	result.success = QuestManager.start_quest(quest_id)
	result.message = "quest_started" if result.success else "quest_start_failed"
	result.data = {"quest_id": quest_id, "source_id": source_id}
	if result.success:
		GameEvents.emit_domain_event("quest_accepted_from_source", result.data)
	return result

func turn_in_quest(quest_id: String, source_id: String = "") -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if quest_id.is_empty():
		result.message = "missing_quest_id"
		return result

	result.success = QuestManager.reward_quest(quest_id)
	result.message = "quest_rewarded" if result.success else "quest_reward_failed"
	result.data = {"quest_id": quest_id, "source_id": source_id}
	if result.success:
		GameEvents.emit_domain_event("quest_turned_in_at_source", result.data)
	return result

func update_progress(objective_type: String, target_id: String, amount: int = 1) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if objective_type.is_empty() or target_id.is_empty():
		result.message = "invalid_payload"
		return result

	QuestManager.update_all_quests(objective_type, target_id, amount)
	result.success = true
	result.message = "quest_progress_updated"
	result.data = {"objective_type": objective_type, "target_id": target_id, "amount": amount}
	return result

func get_journal_view_data() -> Dictionary:
	var active_entries: Array[Dictionary] = []
	for quest_id in QuestManager.active_quests:
		var quest_data: Dictionary = QuestManager.active_quests[quest_id].duplicate(true)
		quest_data["quest_id"] = quest_id
		quest_data["status"] = "active"
		active_entries.append(quest_data)

	var completed_entries: Array[Dictionary] = []
	for quest_id in QuestManager.completed_quests:
		var quest_data := QuestManager.get_quest(quest_id).duplicate(true)
		quest_data["quest_id"] = quest_id
		quest_data["status"] = "completed"
		completed_entries.append(quest_data)

	var rewarded_entries: Array[Dictionary] = []
	for quest_id in QuestManager.rewarded_quests:
		var quest_data := QuestManager.get_quest(quest_id).duplicate(true)
		quest_data["quest_id"] = quest_id
		quest_data["status"] = "rewarded"
		rewarded_entries.append(quest_data)

	return {
		"active": active_entries,
		"completed": completed_entries,
		"rewarded": rewarded_entries
	}
