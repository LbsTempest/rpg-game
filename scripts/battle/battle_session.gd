class_name BattleSession
extends RefCounted

var session_id: String = ""
var player_team: Array[CombatantState] = []
var enemy_team: Array[CombatantState] = []
var round_index: int = 1
var player_turn: bool = true
var result: String = ""
var player_defend_active: bool = false
var logs: PackedStringArray = []

func add_log(message: String) -> void:
	if message.is_empty():
		return
	logs.append(message)

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

func is_active() -> bool:
	return result.is_empty() and get_active_player() != null and get_active_enemy() != null

func mark_result(value: String) -> void:
	result = value
