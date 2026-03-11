extends Node

signal battle_started(enemy: Node2D)
signal battle_ended(result: String, rewards: Dictionary)
signal turn_changed(is_player_turn: bool)
signal battle_log(message: String)
signal battle_state_changed(view_data: Dictionary)

const BATTLE_SCENE_PATH := GameConstants.SCENE_BATTLE

var is_in_battle: bool = false
var current_enemy: Node2D = null
var player: Node = null
var current_session: BattleSession = null

var _battle_scene: Node = null
var _battle_resolver := BattleResolver.new()
var _encounter_service := EncounterService.new()

func start_battle(enemy: Node2D) -> void:
	start_world_encounter(enemy)

func start_world_encounter(enemy: Node2D) -> void:
	if is_in_battle:
		return

	is_in_battle = true
	current_enemy = enemy
	player = Utils.get_group_node("player")
	current_session = _encounter_service.create_world_encounter(player, enemy)

	get_tree().paused = true

	var main_ui = Utils.get_group_node("ui")
	if main_ui:
		main_ui.visible = false

	var battle_scene = preload(BATTLE_SCENE_PATH).instantiate()
	_battle_scene = battle_scene
	battle_scene.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(battle_scene)

	battle_scene.initialize(get_battle_view_data())
	battle_scene.action_selected.connect(_on_player_action)
	battle_scene.flee_requested.connect(_on_flee_attempt)
	battle_scene.skill_selected.connect(_on_skill_selected)
	battle_scene.item_used.connect(_on_item_used)
	UIRouter.register_modal("battle", Callable(), 100, true)

	battle_started.emit(enemy)
	_append_log("战斗开始！遭遇了 %s！" % enemy.enemy_name)
	GameEvents.emit_domain_event("battle_started", {"enemy_name": enemy.enemy_name})

	_start_player_turn()

func end_battle(result: String) -> void:
	if not is_in_battle:
		return

	var rewards := {}
	if current_session != null:
		current_session.mark_result(result)

	match result:
		"victory":
			rewards = _collect_victory_rewards()
			if player and player.has_method("add_experience"):
				player.add_experience(rewards.get("experience", 0))
			InventoryManager.add_gold(rewards.get("gold", 0))
			_award_kill_progress()
			_append_log(
				"战斗胜利！获得 %d 经验值和 %d 金币！" % [rewards.get("experience", 0), rewards.get("gold", 0)]
			)
		"defeat":
			_append_log("战斗失败...")
			_handle_player_defeat()
		"flee":
			_append_log("成功逃跑！")

	_cleanup_battle()
	battle_ended.emit(result, rewards)
	GameEvents.emit_domain_event("battle_ended", {"result": result, "rewards": rewards})

func start_encounter(encounter_id: String) -> bool:
	push_warning("Encounter definitions are not implemented yet: %s" % encounter_id)
	return false

func list_player_combatants() -> Array[Dictionary]:
	if current_session == null:
		return []
	return current_session.list_player_combatants()

func queue_action(actor_id: String, action_id: String, target_spec: Dictionary = {}) -> Dictionary:
	var result := {"success": false, "message": "", "result": ""}
	if not is_in_battle or current_session == null or not current_session.is_active():
		result.message = "battle_not_active"
		return result

	current_session.queue_action(actor_id, action_id, target_spec)
	return resolve_next_turn()

func resolve_next_turn() -> Dictionary:
	var result := {"success": false, "message": "", "result": ""}
	if not is_in_battle or current_session == null or not current_session.is_active():
		result.message = "battle_not_active"
		return result

	if not current_session.player_turn:
		result.message = "enemy_turn_active"
		return result

	var queued_action: Dictionary = current_session.pop_next_action()
	if queued_action.is_empty():
		result.message = "pending_player_action"
		return result

	var action_id: String = queued_action.get("action_id", "")
	var payload: Dictionary = queued_action.get("payload", {})
	var actor_id: String = payload.get("actor_id", "")
	var target_spec: Dictionary = payload.get("target_spec", {})
	var action_result := _battle_resolver.execute_player_action(current_session, actor_id, action_id, target_spec)

	if not String(action_result.get("message", "")).is_empty():
		_append_log(String(action_result["message"]))

	if action_result.get("ended", false):
		var battle_result: String = action_result.get("result", "")
		if battle_result == "flee_failed":
			return _start_enemy_turn()
		end_battle(battle_result)
		result.success = true
		result.result = battle_result
		result.message = action_result.get("message", "")
		return result

	return _start_enemy_turn()

func can_use_skill(actor_id: String, skill_id: String) -> Dictionary:
	var actor := _resolve_player_actor(actor_id)
	if actor == null or actor.source_node == null:
		return {"can_use": false, "reason": "玩家不存在"}
	return SkillManager.can_use_skill(skill_id, actor.source_node)

func use_item_in_battle(user_id: String, item_id: String, target_spec: Dictionary = {}) -> Dictionary:
	var payload := target_spec.duplicate(true)
	payload["item_id"] = item_id
	return queue_action(user_id, GameConstants.ACTION_ITEM, payload)

func get_available_skills_for_ui(actor_id: String = "") -> Array[Dictionary]:
	var actor := _resolve_player_actor(actor_id)
	if actor == null or actor.source_node == null:
		return []
	return SkillManager.get_available_skills_for_ui(actor.source_node)

func get_consumable_items_for_ui(user_id: String = "") -> Array[Dictionary]:
	var actor := _resolve_player_actor(user_id)
	if actor == null:
		return []

	var items: Array[Dictionary] = []
	for item in InventoryManager.get_all_items():
		if item.get("item_type", GameConstants.ITEM_TYPE_CONSUMABLE) == GameConstants.ITEM_TYPE_CONSUMABLE:
			items.append(item)
	return items

func get_battle_view_data() -> Dictionary:
	if current_session == null:
		return {}
	return current_session.to_view_data()

func _cleanup_battle() -> void:
	if _battle_scene:
		_battle_scene.queue_free()
		_battle_scene = null

	is_in_battle = false
	current_enemy = null
	current_session = null

	get_tree().paused = false
	UIRouter.unregister_modal("battle")

	var main_ui = Utils.get_group_node("ui")
	if main_ui:
		main_ui.visible = true

func _start_player_turn() -> void:
	if not is_in_battle or current_session == null or not current_session.is_active():
		return

	current_session.player_turn = true
	turn_changed.emit(true)
	_append_log("玩家回合 - 请选择行动")

func _on_player_action(action: String, data: Dictionary = {}) -> void:
	if not is_in_battle or current_session == null:
		return

	var actor := current_session.get_active_player()
	if actor == null:
		return

	queue_action(actor.combatant_id, action, data)

func _on_skill_selected(skill_id: String) -> void:
	if current_session == null:
		return

	var actor := current_session.get_active_player()
	if actor == null:
		return

	queue_action(actor.combatant_id, GameConstants.ACTION_SKILL, {"skill_id": skill_id})

func _on_item_used(item_id: String) -> void:
	if current_session == null:
		return

	var actor := current_session.get_active_player()
	if actor == null:
		return

	use_item_in_battle(actor.combatant_id, item_id)

func _start_enemy_turn() -> Dictionary:
	var result := {"success": true, "message": "", "result": ""}
	if not is_in_battle or current_session == null or not current_session.is_active():
		result.success = false
		result.message = "battle_not_active"
		return result

	current_session.player_turn = false
	turn_changed.emit(false)

	var active_enemy := current_session.get_active_enemy()
	if active_enemy != null:
		_append_log("%s 的回合..." % active_enemy.display_name)

	var enemy_result := _battle_resolver.execute_enemy_turn(current_session)
	if not String(enemy_result.get("message", "")).is_empty():
		_append_log(String(enemy_result["message"]))

	if enemy_result.get("player_defeated", false):
		end_battle("defeat")
		result.result = "defeat"
		return result

	if enemy_result.get("enemy_defeated", false):
		end_battle("victory")
		result.result = "victory"
		return result

	_start_player_turn()
	result.message = enemy_result.get("message", "")
	return result

func _on_flee_attempt() -> void:
	_on_player_action(GameConstants.ACTION_FLEE, {})

func _handle_player_defeat() -> void:
	player.current_health = max(1, int(player.max_health * 0.3))
	player.position = Vector2(128, 128)
	player.health_changed.emit(player.current_health, player.max_health)
	_append_log("你被打败了... 已恢复部分生命值")

func _resolve_player_actor(actor_id: String = "") -> CombatantState:
	if current_session == null:
		return null

	if not actor_id.is_empty():
		var actor := current_session.find_combatant(actor_id)
		if actor != null and actor.faction == "player":
			return actor

	return current_session.get_active_player()

func _collect_victory_rewards() -> Dictionary:
	var rewards := {"experience": 0, "gold": 0}
	if current_session == null:
		return rewards

	for enemy_state in current_session.enemy_team:
		if enemy_state.source_node == null:
			continue
		if "experience_reward" in enemy_state.source_node:
			rewards["experience"] += int(enemy_state.source_node.experience_reward)
		if "gold_reward" in enemy_state.source_node:
			rewards["gold"] += int(enemy_state.source_node.gold_reward)

	return rewards

func _award_kill_progress() -> void:
	if current_session == null:
		return

	for enemy_state in current_session.enemy_team:
		var target_id: String = enemy_state.metadata.get("definition_id", enemy_state.display_name)
		if target_id.is_empty():
			target_id = enemy_state.display_name
		QuestService.update_progress(GameConstants.OBJECTIVE_KILL, target_id, 1)

func _append_log(message: String) -> void:
	if message.is_empty():
		return
	if current_session != null:
		current_session.add_log(message)
	battle_log.emit(message)
	_emit_battle_state()

func _emit_battle_state() -> void:
	if current_session == null:
		return
	battle_state_changed.emit(current_session.to_view_data())
