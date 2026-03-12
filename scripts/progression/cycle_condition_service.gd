class_name CycleConditionService
extends RefCounted

func evaluate(cycle_index: int, conditions: Dictionary) -> Dictionary:
	var result := {"passed": true, "reason": ""}
	var min_cycle: int = int(conditions.get("min_cycle", -1))
	var max_cycle: int = int(conditions.get("max_cycle", -1))

	if min_cycle >= 0 and cycle_index < min_cycle:
		result.passed = false
		result.reason = "cycle_too_low"
		return result

	if max_cycle >= 0 and cycle_index > max_cycle:
		result.passed = false
		result.reason = "cycle_too_high"
		return result

	return result

func is_content_available(cycle_index: int, conditions: Dictionary) -> bool:
	return evaluate(cycle_index, conditions).passed
