class_name EncounterService
extends RefCounted

func create_world_encounter(player_node: Node, enemy_node: Node) -> BattleSession:
	return create_world_encounter_from_teams([player_node], [enemy_node])

func create_content_encounter(player_nodes: Array, enemy_scene_paths: Array) -> BattleSession:
	var enemy_nodes: Array = []
	for scene_path in enemy_scene_paths:
		if not scene_path is String:
			continue
		var packed_scene: PackedScene = load(String(scene_path))
		if packed_scene == null:
			continue
		var enemy_node := packed_scene.instantiate()
		enemy_nodes.append(enemy_node)
	return create_world_encounter_from_teams(player_nodes, enemy_nodes)

func create_world_encounter_from_teams(player_nodes: Array, enemy_nodes: Array) -> BattleSession:
	var session := BattleSession.new()
	session.session_id = "battle_%s" % str(Time.get_unix_time_from_system())

	var player_index: int = 0
	for player_node in player_nodes:
		if player_node:
			var player_id := "player_%d" % player_index
			session.player_team.append(CombatantState.from_node(player_id, "player", player_node))
			player_index += 1

	for enemy_node in enemy_nodes:
		if enemy_node:
			var enemy_id := "enemy_%s" % str(enemy_node.get_instance_id())
			session.enemy_team.append(CombatantState.from_node(enemy_id, "enemy", enemy_node))

	session.refresh()
	return session
