extends Node

signal cycle_started(cycle_index: int, summary: Dictionary)

const CARRY_OVER_POLICY_SCRIPT = preload("res://scripts/progression/carry_over_policy.gd")
const CYCLE_CONDITION_SERVICE_SCRIPT = preload("res://scripts/progression/cycle_condition_service.gd")

var _carry_over_policy: CarryOverPolicy = CARRY_OVER_POLICY_SCRIPT.new()
var _cycle_condition_service: CycleConditionService = CYCLE_CONDITION_SERVICE_SCRIPT.new()
var _last_run_snapshot: Dictionary = {}
var _last_cycle_summary: Dictionary = {}

func start_new_cycle(profile_slot_id: String = "0") -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	_last_run_snapshot = _snapshot_current_run()

	Session.profile.cycle_index += 1
	Session.start_new_run()
	_reset_services_for_new_cycle()
	_apply_starting_items()

	_last_cycle_summary = apply_carry_over_rules()
	result.success = true
	result.message = "cycle_started"
	result.data = {
		"cycle_index": Session.profile.cycle_index,
		"summary": _last_cycle_summary,
		"profile_slot_id": profile_slot_id
	}

	cycle_started.emit(Session.profile.cycle_index, _last_cycle_summary)
	GameEvents.emit_domain_event("cycle_started", result.data)
	return result

func get_cycle_index() -> int:
	return Session.profile.cycle_index

func is_ng_plus() -> bool:
	return get_cycle_index() > 1

func apply_carry_over_rules(policy: Dictionary = {}) -> Dictionary:
	var summary: Dictionary = _carry_over_policy.apply(_last_run_snapshot, Session.run_state, policy)
	_last_cycle_summary = summary
	return summary

func is_content_available(content_id: String, conditions: Dictionary) -> bool:
	var _unused_content_id := content_id
	return _cycle_condition_service.is_content_available(get_cycle_index(), conditions)

func get_last_cycle_summary() -> Dictionary:
	return _last_cycle_summary.duplicate(true)

func _snapshot_current_run() -> Dictionary:
	return {
		"inventory": Session.run_state.inventory.to_save_data(),
		"player": {
			"learned_skills": Session.run_state.party.player_state.learned_skills.duplicate(),
			"skill_cooldowns": Session.run_state.party.player_state.skill_cooldowns.duplicate(true)
		},
		"story": {
			"flags": Session.run_state.story.flags.duplicate(true),
			"branch_choices": Session.run_state.story.branch_choices.duplicate(true)
		}
	}

func _reset_services_for_new_cycle() -> void:
	QuestService.reset_state()
	ShopService.reset_state()
	SkillService.reset_skills()
	InventoryService.reset_state()
	EnemyStateService.reset_all_enemies()

func _apply_starting_items() -> void:
	for entry in ContentDB.get_starting_item_entries():
		var item_id: String = entry.get("item_id", "")
		var quantity: int = int(entry.get("quantity", 1))
		if item_id.is_empty() or quantity <= 0:
			continue

		var item_data: Dictionary = ContentDB.get_item_definition(item_id)
		if item_data.is_empty():
			push_warning("Missing starting item definition: " + item_id)
			continue
		InventoryService.add_item(item_data, quantity)

	InventoryService.add_gold(ContentDB.get_starting_gold())
