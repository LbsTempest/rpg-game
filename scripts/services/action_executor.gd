extends Node

func execute(action_id: String, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}

	match action_id:
		"open_shop":
			result = _execute_open_shop(payload, context)
		"accept_quest", "start_quest":
			result = _execute_start_quest(payload, context)
		"reward_quest", "turn_in_quest":
			result = _execute_reward_quest(payload, context)
		"start_story_segment":
			result = _execute_start_story_segment(payload)
		"advance_story":
			result = _execute_advance_story()
		"choose_story_branch":
			result = _execute_choose_story_branch(payload)
		"start_new_cycle":
			result = _execute_start_new_cycle(payload)
		"set_story_flag":
			result = _execute_set_story_flag(payload)
		"clear_story_flag":
			result = _execute_clear_story_flag(payload)
		"grant_gold":
			result = _execute_grant_gold(payload)
		"grant_item":
			result = _execute_grant_item(payload)
		"update_quest_progress":
			result = _execute_update_quest_progress(payload)
		"emit_event":
			result = _execute_emit_event(payload)
		_:
			result.message = "unknown_action:" + action_id

	GameEvents.emit_action_result(action_id, result.success, payload, context)
	return result

func _execute_open_shop(payload: Dictionary, context: Dictionary) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var shop_id: String = payload.get("shop_id", "")
	var source_id: String = context.get("source_id", "")

	if shop_id.is_empty():
		var npc = context.get("npc")
		if npc and "shop_id" in npc:
			shop_id = String(npc.shop_id)
			if source_id.is_empty():
				source_id = String(npc.name)

	if shop_id.is_empty():
		result.message = "missing_shop_id"
		return result

	result = ShopService.open_shop(shop_id, source_id)
	if result.success:
		GameEvents.emit_domain_event("shop_opened", {"shop_id": shop_id})
	return result

func _execute_start_quest(payload: Dictionary, context: Dictionary) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var quest_id: String = payload.get("quest_id", "")
	var source_id: String = context.get("source_id", "")

	if quest_id.is_empty():
		var npc = context.get("npc")
		if npc and "gives_quest" in npc:
			quest_id = String(npc.gives_quest)
			if source_id.is_empty():
				source_id = String(npc.name)

	if quest_id.is_empty():
		result.message = "missing_quest_id"
		return result

	result = QuestService.accept_quest(quest_id, source_id)
	if result.success:
		GameEvents.emit_domain_event("quest_started", {"quest_id": quest_id})
	return result

func _execute_reward_quest(payload: Dictionary, context: Dictionary) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var quest_id: String = payload.get("quest_id", "")
	var source_id: String = context.get("source_id", "")

	if quest_id.is_empty():
		var npc = context.get("npc")
		if npc and "completes_quest" in npc:
			quest_id = String(npc.completes_quest)
			if source_id.is_empty():
				source_id = String(npc.name)

	if quest_id.is_empty():
		result.message = "missing_quest_id"
		return result

	result = QuestService.turn_in_quest(quest_id, source_id)
	if result.success:
		GameEvents.emit_domain_event("quest_rewarded", {"quest_id": quest_id})
	return result

func _execute_set_story_flag(payload: Dictionary) -> Dictionary:
	return StoryService.set_story_flag(String(payload.get("flag_id", "")), bool(payload.get("value", true)))

func _execute_clear_story_flag(payload: Dictionary) -> Dictionary:
	return StoryService.clear_story_flag(String(payload.get("flag_id", "")))

func _execute_start_story_segment(payload: Dictionary) -> Dictionary:
	var segment_id: String = payload.get("segment_id", "")
	if segment_id.is_empty():
		return {"success": false, "message": "missing_segment_id", "data": {}}
	return StoryService.start_story_segment(segment_id)

func _execute_advance_story() -> Dictionary:
	return StoryService.advance_story()

func _execute_choose_story_branch(payload: Dictionary) -> Dictionary:
	var branch_id: String = payload.get("branch_id", "")
	if branch_id.is_empty():
		return {"success": false, "message": "missing_branch_id", "data": {}}
	return StoryService.choose_story_branch(branch_id)

func _execute_start_new_cycle(payload: Dictionary) -> Dictionary:
	var profile_slot_id: String = String(payload.get("profile_slot_id", "0"))
	return CycleService.start_new_cycle(profile_slot_id)

func _execute_grant_gold(payload: Dictionary) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var amount: int = int(payload.get("amount", 0))
	if amount <= 0:
		result.message = "invalid_gold_amount"
		return result

	result.success = RewardService.grant_gold(amount)
	result.message = "gold_granted" if result.success else "gold_grant_failed"
	result.data = {"amount": amount}
	return result

func _execute_grant_item(payload: Dictionary) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var item_id: String = payload.get("item_id", "")
	var quantity: int = int(payload.get("quantity", 1))
	if item_id.is_empty() or quantity <= 0:
		result.message = "invalid_item_payload"
		return result

	var item_data := ContentDB.get_item_definition(item_id)
	if item_data.is_empty():
		result.message = "unknown_item_id"
		return result

	result.success = RewardService.grant_item(item_id, quantity)
	result.message = "item_granted" if result.success else "item_grant_failed"
	result.data = {"item_id": item_id, "quantity": quantity}
	return result

func _execute_update_quest_progress(payload: Dictionary) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var objective_type: String = payload.get("objective_type", "")
	var target_id: String = payload.get("target_id", payload.get("target", ""))
	var amount: int = int(payload.get("amount", 1))
	if objective_type.is_empty() or target_id.is_empty():
		result.message = "invalid_quest_progress_payload"
		return result

	result = QuestService.update_progress(objective_type, target_id, amount)
	return result

func _execute_emit_event(payload: Dictionary) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var event_id: String = payload.get("event_id", "")
	var event_payload: Dictionary = payload.get("payload", {})
	if event_id.is_empty():
		result.message = "missing_event_id"
		return result

	GameEvents.emit_domain_event(event_id, event_payload)
	result.success = true
	result.message = "event_emitted"
	result.data = {"event_id": event_id}
	return result
