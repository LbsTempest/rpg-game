class_name BattleSession
extends RefCounted

var session_id: String = ""
var player_team: Array[CombatantState] = []
var enemy_team: Array[CombatantState] = []
var round_index: int = 1
var player_turn: bool = true
var result: String = ""
var logs: PackedStringArray = []
var queued_actions: Array[Dictionary] = []

func add_log(message: String) -> void:
	if message.is_empty():
		return
	logs.append(message)

func queue_action(actor_id: String, action_id: String, target_spec: Dictionary = {}) -> void:
	var payload := {
		"actor_id": actor_id,
		"target_spec": target_spec.duplicate(true)
	}
	queued_actions.append(ActionDefinition.build(action_id, payload))

func pop_next_action() -> Dictionary:
	if queued_actions.is_empty():
		return {}

	var action: Dictionary = queued_actions[0]
	queued_actions.remove_at(0)
	return action

func has_pending_actions() -> bool:
	return not queued_actions.is_empty()

func refresh() -> void:
	for combatant in player_team:
		combatant.sync_from_source()
	for combatant in enemy_team:
		combatant.sync_from_source()

func get_active_player() -> CombatantState:
	for combatant in player_team:
		if combatant.is_alive:
			return combatant
	return null

func get_active_enemy() -> CombatantState:
	for combatant in enemy_team:
		if combatant.is_alive:
			return combatant
	return null

func find_combatant(combatant_id: String) -> CombatantState:
	for combatant in player_team:
		if combatant.combatant_id == combatant_id:
			return combatant
	for combatant in enemy_team:
		if combatant.combatant_id == combatant_id:
			return combatant
	return null

func is_active() -> bool:
	return result.is_empty() and get_active_player() != null and get_active_enemy() != null

func mark_result(value: String) -> void:
	result = value

func list_player_combatants() -> Array[Dictionary]:
	refresh()
	return _serialize_team(player_team)

func list_enemy_combatants() -> Array[Dictionary]:
	refresh()
	return _serialize_team(enemy_team)

func to_view_data() -> Dictionary:
	refresh()
	var active_player := get_active_player()
	var active_enemy := get_active_enemy()
	return {
		"session_id": session_id,
		"round_index": round_index,
		"player_turn": player_turn,
		"result": result,
		"active_player_id": active_player.combatant_id if active_player != null else "",
		"active_enemy_id": active_enemy.combatant_id if active_enemy != null else "",
		"player_team": _serialize_team(player_team),
		"enemy_team": _serialize_team(enemy_team),
		"queued_actions": queued_actions.duplicate(true),
		"logs": logs.duplicate()
	}

func _serialize_team(team: Array[CombatantState]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for combatant in team:
		entries.append(combatant.to_view_data())
	return entries
