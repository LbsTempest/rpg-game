class_name TargetingService
extends RefCounted

func resolve_targets(session: BattleSession, actor: CombatantState, target_spec: Dictionary = {}) -> Array[CombatantState]:
	if session == null or actor == null:
		return []

	if target_spec.has("target_id"):
		var explicit_target := _find_target_by_id(session, String(target_spec["target_id"]))
		return [explicit_target] if explicit_target != null else []

	var target_type: String = target_spec.get("target_type", "")
	if target_type.is_empty():
		target_type = "enemy_single" if actor.faction == "player" else "ally_single"

	match target_type:
		"self":
			return [actor]
		"ally_single":
			return _single_target(session.player_team) if actor.faction == "player" else _single_target(session.enemy_team)
		"ally_all":
			return _all_alive(session.player_team) if actor.faction == "player" else _all_alive(session.enemy_team)
		"enemy", "enemy_single":
			return _single_target(session.enemy_team) if actor.faction == "player" else _single_target(session.player_team)
		"enemy_all":
			return _all_alive(session.enemy_team) if actor.faction == "player" else _all_alive(session.player_team)
		_:
			return _single_target(session.enemy_team) if actor.faction == "player" else _single_target(session.player_team)

func _find_target_by_id(session: BattleSession, target_id: String) -> CombatantState:
	for combatant in session.player_team:
		if combatant.combatant_id == target_id:
			return combatant
	for combatant in session.enemy_team:
		if combatant.combatant_id == target_id:
			return combatant
	return null

func _first_alive(team: Array[CombatantState]) -> CombatantState:
	for combatant in team:
		if combatant and combatant.is_alive:
			return combatant
	return null

func _single_target(team: Array[CombatantState]) -> Array[CombatantState]:
	var target := _first_alive(team)
	if target == null:
		return []
	return [target]

func _all_alive(team: Array[CombatantState]) -> Array[CombatantState]:
	var result: Array[CombatantState] = []
	for combatant in team:
		if combatant and combatant.is_alive:
			result.append(combatant)
	return result
