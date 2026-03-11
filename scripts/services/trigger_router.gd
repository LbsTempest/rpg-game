extends Node

func execute_action(action, payload: Dictionary = {}, context: Dictionary = {}) -> Dictionary:
	var action_id: String = ""
	var action_payload: Dictionary = payload.duplicate(true)
	var conditions: Dictionary = {}

	if action is String:
		action_id = action
	elif action is Dictionary:
		action_id = String(action.get("id", action.get("action", "")))
		if action.has("payload") and action.payload is Dictionary:
			action_payload.merge(action.payload, true)
		if action.has("conditions") and action.conditions is Dictionary:
			conditions = action.conditions
	else:
		return {"success": false, "message": "invalid_action_type", "data": {}}

	if action_id.is_empty():
		return {"success": false, "message": "missing_action_id", "data": {}}

	var condition_check := ConditionService.evaluate(conditions, context)
	if not condition_check.passed:
		return {"success": false, "message": "conditions_not_met:" + condition_check.reason, "data": {}}

	return ActionExecutor.execute(action_id, action_payload, context)

func execute_dialogue_option(option_data: Dictionary, context: Dictionary = {}) -> Dictionary:
	if not option_data.has("action"):
		return {"success": false, "message": "missing_action", "data": {}}

	var action_payload: Dictionary = {}
	if option_data.has("action_payload") and option_data.action_payload is Dictionary:
		action_payload = option_data.action_payload.duplicate(true)

	if option_data.has("conditions") and option_data.conditions is Dictionary:
		return execute_action(
			{"id": option_data.action, "payload": action_payload, "conditions": option_data.conditions},
			{},
			context
		)

	return execute_action(option_data.action, action_payload, context)
