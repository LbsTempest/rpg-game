extends Node

signal domain_event_emitted(event_id: String, payload: Dictionary)
signal action_executed(action_id: String, success: bool, payload: Dictionary, context: Dictionary)
signal condition_evaluated(passed: bool, reason: String, conditions: Dictionary, context: Dictionary)

func emit_domain_event(event_id: String, payload: Dictionary = {}) -> void:
	domain_event_emitted.emit(event_id, payload.duplicate(true))

func emit_action_result(action_id: String, success: bool, payload: Dictionary = {}, context: Dictionary = {}) -> void:
	action_executed.emit(action_id, success, payload.duplicate(true), context.duplicate(true))

func emit_condition_result(passed: bool, reason: String, conditions: Dictionary = {}, context: Dictionary = {}) -> void:
	condition_evaluated.emit(passed, reason, conditions.duplicate(true), context.duplicate(true))
