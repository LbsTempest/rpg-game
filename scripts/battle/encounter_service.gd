class_name EncounterService
extends RefCounted

func create_world_encounter(player_node: Node, enemy_node: Node) -> BattleSession:
	var session := BattleSession.new()
	session.session_id = str(Time.get_unix_time_from_system())

	if player_node:
		session.player_team.append(CombatantState.from_node("player_0", "player", player_node))

	if enemy_node:
		var enemy_id := "enemy_%s" % str(enemy_node.get_instance_id())
		session.enemy_team.append(CombatantState.from_node(enemy_id, "enemy", enemy_node))

	session.refresh()
	return session
