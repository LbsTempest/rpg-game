extends Node

func evaluate(conditions: Dictionary, context: Dictionary = {}) -> Dictionary:
	var result := {"passed": true, "reason": ""}
	if conditions.is_empty():
		GameEvents.emit_condition_result(true, "", conditions, context)
		return result

	var flag_check := _check_flags(conditions)
	if not flag_check.passed:
		result = flag_check
		GameEvents.emit_condition_result(false, result.reason, conditions, context)
		return result

	var cycle_check := _check_cycle(conditions)
	if not cycle_check.passed:
		result = cycle_check
		GameEvents.emit_condition_result(false, result.reason, conditions, context)
		return result

	var quest_check := _check_quests(conditions)
	if not quest_check.passed:
		result = quest_check
		GameEvents.emit_condition_result(false, result.reason, conditions, context)
		return result

	var item_check := _check_items(conditions)
	if not item_check.passed:
		result = item_check
		GameEvents.emit_condition_result(false, result.reason, conditions, context)
		return result

	GameEvents.emit_condition_result(true, "", conditions, context)
	return result

func _check_flags(conditions: Dictionary) -> Dictionary:
	var flags: Dictionary = Session.run_state.story.flags

	for flag_id in conditions.get("requires_flags", []):
		if not flags.get(flag_id, false):
			return {"passed": false, "reason": "missing_required_flag:" + String(flag_id)}

	for flag_id in conditions.get("forbids_flags", []):
		if flags.get(flag_id, false):
			return {"passed": false, "reason": "forbidden_flag_present:" + String(flag_id)}

	return {"passed": true, "reason": ""}

func _check_cycle(conditions: Dictionary) -> Dictionary:
	if not conditions.has("min_cycle") and not conditions.has("max_cycle"):
		return {"passed": true, "reason": ""}

	var available: bool = CycleService.is_content_available("", conditions)
	if available:
		return {"passed": true, "reason": ""}

	var cycle_index: int = CycleService.get_cycle_index()
	var min_cycle: int = int(conditions.get("min_cycle", -1))
	var max_cycle: int = int(conditions.get("max_cycle", -1))
	if min_cycle >= 0 and cycle_index < min_cycle:
		return {"passed": false, "reason": "cycle_too_low"}
	if max_cycle >= 0 and cycle_index > max_cycle:
		return {"passed": false, "reason": "cycle_too_high"}
	return {"passed": false, "reason": "cycle_constraint_failed"}

func _check_quests(conditions: Dictionary) -> Dictionary:
	for quest_id in conditions.get("requires_quests", []):
		var status := QuestService.get_quest_status(String(quest_id))
		if status != "rewarded":
			return {"passed": false, "reason": "required_quest_not_rewarded:" + String(quest_id)}

	var required_status_map: Dictionary = conditions.get("quest_status", {})
	for quest_id in required_status_map:
		var expected_status: String = String(required_status_map[quest_id])
		var actual_status: String = QuestService.get_quest_status(String(quest_id))
		if actual_status != expected_status:
			return {"passed": false, "reason": "quest_status_mismatch:" + String(quest_id)}

	return {"passed": true, "reason": ""}

func _check_items(conditions: Dictionary) -> Dictionary:
	for item_req in conditions.get("requires_items", []):
		if not item_req is Dictionary:
			continue
		var item_id: String = item_req.get("item_id", "")
		var quantity: int = int(item_req.get("quantity", 1))
		if InventoryManager.get_item_count_by_id(item_id) < quantity:
			return {"passed": false, "reason": "missing_required_item:" + item_id}

	return {"passed": true, "reason": ""}
