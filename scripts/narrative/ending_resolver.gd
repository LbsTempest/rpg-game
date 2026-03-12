class_name EndingResolver
extends RefCounted

const DEFAULT_ENDING_ID := "ending_default"

func resolve_ending_id(story_state: StoryState, definitions: Dictionary) -> String:
	if story_state == null:
		return DEFAULT_ENDING_ID

	var rules: Array[Dictionary] = _collect_rules(definitions)
	rules.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return int(a.get("priority", 0)) > int(b.get("priority", 0))
	)

	for rule in rules:
		if _match_rule(story_state, rule):
			return String(rule.get("ending_id", DEFAULT_ENDING_ID))

	return DEFAULT_ENDING_ID

func _collect_rules(definitions: Dictionary) -> Array[Dictionary]:
	var rules: Array[Dictionary] = []
	for segment_id in definitions:
		var definition: Dictionary = definitions[segment_id]
		if String(definition.get("type", "")) != "ending_rule":
			continue

		var rule := definition.duplicate(true)
		rule["rule_id"] = String(segment_id)
		rules.append(rule)
	return rules

func _match_rule(story_state: StoryState, rule: Dictionary) -> bool:
	var required_flags: Array = rule.get("required_flags", [])
	for flag in required_flags:
		if flag is String and not bool(story_state.flags.get(flag, false)):
			return false

	var forbidden_flags: Array = rule.get("forbidden_flags", [])
	for flag in forbidden_flags:
		if flag is String and bool(story_state.flags.get(flag, false)):
			return false

	var required_choices: Dictionary = rule.get("required_choices", {})
	for segment_id in required_choices:
		var expected_choice: String = String(required_choices[segment_id])
		if String(story_state.branch_choices.get(segment_id, "")) != expected_choice:
			return false

	return true
