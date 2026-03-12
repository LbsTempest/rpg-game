class_name CarryOverPolicy
extends RefCounted

func default_policy() -> Dictionary:
	return {
		"carry_gold_ratio": 0.5,
		"carry_skill_progress": true,
		"carry_item_ids": []
	}

func apply(previous_run_snapshot: Dictionary, run_state: RunState, policy: Dictionary = {}) -> Dictionary:
	var resolved_policy: Dictionary = default_policy()
	resolved_policy.merge(policy, true)

	var summary := {
		"carried_gold": 0,
		"carried_skills": 0,
		"carried_items": []
	}
	if previous_run_snapshot.is_empty() or run_state == null:
		return summary

	var previous_inventory: Dictionary = previous_run_snapshot.get("inventory", {})
	var previous_player: Dictionary = previous_run_snapshot.get("player", {})

	var carried_gold: int = int(previous_inventory.get("gold", 0) * float(resolved_policy.get("carry_gold_ratio", 0.0)))
	if carried_gold > 0:
		run_state.inventory.gold += carried_gold
		summary["carried_gold"] = carried_gold

	if bool(resolved_policy.get("carry_skill_progress", true)):
		var learned_skills: Array[String] = []
		for skill_id in previous_player.get("learned_skills", []):
			if skill_id is String:
				learned_skills.append(skill_id)

		run_state.party.player_state.learned_skills = learned_skills
		run_state.party.player_state.skill_cooldowns.clear()
		summary["carried_skills"] = learned_skills.size()

	var carry_item_ids: Array = resolved_policy.get("carry_item_ids", [])
	for item_id in carry_item_ids:
		if not item_id is String:
			continue
		var quantity: int = int(previous_inventory.get("item_quantities", {}).get(item_id, 0))
		if quantity <= 0:
			continue

		var item_definition: Dictionary = previous_inventory.get("item_definitions", {}).get(item_id, {})
		if item_definition.is_empty():
			item_definition = ContentDB.get_item_definition(item_id)
		if item_definition.is_empty():
			continue

		run_state.inventory.item_definitions[item_id] = item_definition.duplicate(true)
		run_state.inventory.item_quantities[item_id] = quantity
		summary["carried_items"].append({"item_id": item_id, "quantity": quantity})

	return summary
