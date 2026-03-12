extends Node

signal story_segment_started(segment_id: String)
signal story_segment_advanced(segment_id: String, step_index: int)
signal story_branch_chosen(segment_id: String, branch_id: String)
signal story_flag_changed(flag_id: String, value: bool)
signal story_segment_finished(segment_id: String)

const ENDING_RESOLVER_SCRIPT = preload("res://scripts/narrative/ending_resolver.gd")

var _ending_resolver: EndingResolver = ENDING_RESOLVER_SCRIPT.new()

func start_story_segment(segment_id: String) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if segment_id.is_empty():
		result.message = "missing_segment_id"
		return result

	var segment_definition: Dictionary = ContentDB.get_story_segment(segment_id)
	if segment_definition.is_empty():
		result.message = "story_segment_not_found"
		return result

	var state: StoryState = _story_state()
	state.current_segment_id = segment_id
	state.current_step_index = 0

	_execute_actions(
		segment_definition.get("on_start_actions", []),
		{"source": "story", "segment_id": segment_id, "phase": "start"}
	)

	result.success = true
	result.message = "story_segment_started"
	result.data = {"segment_id": segment_id, "step_index": state.current_step_index}

	story_segment_started.emit(segment_id)
	GameEvents.emit_domain_event("story_segment_started", result.data)
	return result

func advance_story() -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var state: StoryState = _story_state()
	if state.current_segment_id.is_empty():
		result.message = "story_not_active"
		return result

	var segment_definition: Dictionary = ContentDB.get_story_segment(state.current_segment_id)
	if segment_definition.is_empty():
		result.message = "story_segment_not_found"
		return result

	var steps: Array = segment_definition.get("steps", [])
	if steps.is_empty():
		_finish_current_segment(segment_definition)
		result.success = true
		result.message = "story_segment_finished"
		result.data = {"finished": true}
		return result

	state.current_step_index += 1
	if state.current_step_index >= steps.size():
		_finish_current_segment(segment_definition)
		result.success = true
		result.message = "story_segment_finished"
		result.data = {"finished": true}
		return result

	result.success = true
	result.message = "story_advanced"
	result.data = {
		"segment_id": state.current_segment_id,
		"step_index": state.current_step_index,
		"step": steps[state.current_step_index]
	}

	story_segment_advanced.emit(state.current_segment_id, state.current_step_index)
	GameEvents.emit_domain_event("story_advanced", result.data)
	return result

func choose_story_branch(branch_id: String) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	var state: StoryState = _story_state()
	if state.current_segment_id.is_empty():
		result.message = "story_not_active"
		return result
	if branch_id.is_empty():
		result.message = "missing_branch_id"
		return result

	var segment_id: String = state.current_segment_id
	var segment_definition: Dictionary = ContentDB.get_story_segment(segment_id)
	var branches: Dictionary = segment_definition.get("branches", {})
	if not branches.has(branch_id):
		result.message = "story_branch_not_found"
		return result

	var branch_definition: Dictionary = branches[branch_id]
	state.branch_choices[segment_id] = branch_id
	_apply_branch_flags(branch_definition)
	_execute_actions(
		branch_definition.get("actions", []),
		{"source": "story", "segment_id": segment_id, "branch_id": branch_id, "phase": "branch"}
	)

	story_branch_chosen.emit(segment_id, branch_id)
	GameEvents.emit_domain_event("story_branch_chosen", {"segment_id": segment_id, "branch_id": branch_id})

	var next_segment_id: String = String(branch_definition.get("next_segment_id", ""))
	if not next_segment_id.is_empty():
		return start_story_segment(next_segment_id)

	if bool(branch_definition.get("complete_segment", true)):
		_finish_current_segment(segment_definition)

	result.success = true
	result.message = "story_branch_chosen"
	result.data = {
		"segment_id": segment_id,
		"branch_id": branch_id,
		"finished": bool(branch_definition.get("complete_segment", true))
	}
	return result

func set_story_flag(flag_id: String, value: bool = true) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if flag_id.is_empty():
		result.message = "missing_flag_id"
		return result

	var state: StoryState = _story_state()
	state.flags[flag_id] = value

	result.success = true
	result.message = "flag_set"
	result.data = {"flag_id": flag_id, "value": value}

	story_flag_changed.emit(flag_id, value)
	GameEvents.emit_domain_event("story_flag_changed", result.data)
	return result

func clear_story_flag(flag_id: String) -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if flag_id.is_empty():
		result.message = "missing_flag_id"
		return result

	var state: StoryState = _story_state()
	state.flags.erase(flag_id)

	result.success = true
	result.message = "flag_cleared"
	result.data = {"flag_id": flag_id, "value": false}

	story_flag_changed.emit(flag_id, false)
	GameEvents.emit_domain_event("story_flag_changed", result.data)
	return result

func has_story_flag(flag_id: String) -> bool:
	if flag_id.is_empty():
		return false
	return bool(_story_state().flags.get(flag_id, false))

func resolve_ending_id() -> String:
	return _ending_resolver.resolve_ending_id(_story_state(), ContentDB.get_all_story_segments())

func get_current_segment_id() -> String:
	return _story_state().current_segment_id

func get_current_step_index() -> int:
	return _story_state().current_step_index

func get_current_segment_definition() -> Dictionary:
	var segment_id: String = get_current_segment_id()
	if segment_id.is_empty():
		return {}
	return ContentDB.get_story_segment(segment_id)

func get_current_step() -> Dictionary:
	var segment_definition: Dictionary = get_current_segment_definition()
	if segment_definition.is_empty():
		return {}

	var steps: Array = segment_definition.get("steps", [])
	if steps.is_empty():
		return {}

	var step_index: int = clampi(get_current_step_index(), 0, steps.size() - 1)
	if step_index >= steps.size():
		return {}
	return steps[step_index]

func is_story_active() -> bool:
	return not get_current_segment_id().is_empty()

func _story_state() -> StoryState:
	return Session.run_state.story

func _apply_branch_flags(branch_definition: Dictionary) -> void:
	var flags_to_set: Dictionary = branch_definition.get("set_flags", {})
	for flag_id in flags_to_set:
		set_story_flag(String(flag_id), bool(flags_to_set[flag_id]))

func _execute_actions(actions: Array, context: Dictionary) -> void:
	for action in actions:
		if action is String:
			ActionExecutor.execute(String(action), {}, context)
			continue

		if not (action is Dictionary):
			continue

		var action_id: String = String(action.get("id", action.get("action", "")))
		var payload: Dictionary = action.get("payload", {}).duplicate(true)
		if action_id.is_empty():
			continue

		match action_id:
			"set_story_flag":
				set_story_flag(String(payload.get("flag_id", "")), bool(payload.get("value", true)))
			"clear_story_flag":
				clear_story_flag(String(payload.get("flag_id", "")))
			_:
				ActionExecutor.execute(action_id, payload, context)

func _finish_current_segment(segment_definition: Dictionary) -> void:
	var state: StoryState = _story_state()
	var finished_segment_id: String = state.current_segment_id

	_execute_actions(
		segment_definition.get("on_complete_actions", []),
		{"source": "story", "segment_id": finished_segment_id, "phase": "complete"}
	)

	state.current_segment_id = ""
	state.current_step_index = 0

	story_segment_finished.emit(finished_segment_id)
	GameEvents.emit_domain_event("story_segment_finished", {"segment_id": finished_segment_id})

	var next_segment_id: String = String(segment_definition.get("next_segment_id", ""))
	if not next_segment_id.is_empty():
		start_story_segment(next_segment_id)
