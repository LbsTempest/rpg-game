class_name BattleResolver
extends RefCounted

var _targeting := TargetingService.new()

func execute_player_action(
	session: BattleSession,
	actor_id: String,
	action_id: String,
	target_spec: Dictionary = {}
) -> Dictionary:
	var result := {"ended": false, "result": "", "message": ""}
	if session == null:
		result.message = "battle_session_missing"
		return result

	session.refresh()
	var actor := _resolve_actor(session, actor_id, "player")
	if actor == null or actor.source_node == null:
		result.message = "player_actor_missing"
		return result

	if session.get_active_enemy() == null:
		result.ended = true
		result.result = "victory"
		result.message = "战斗结束"
		return result

	var player_node: Node = actor.source_node

	match action_id:
		GameConstants.ACTION_ATTACK:
			var attack_targets := _resolve_targets(session, actor, target_spec, "enemy_single")
			if attack_targets.is_empty():
				result.message = "没有可用目标"
				return result

			var attack_target := attack_targets[0]
			var damage: int = _get_attack_value(actor)
			if attack_target.source_node and attack_target.source_node.has_method("take_damage"):
				attack_target.source_node.take_damage(damage)
			result.message = "你对 %s 造成 %d 点伤害！" % [attack_target.display_name, damage]

		GameConstants.ACTION_DEFEND:
			actor.set_defending(true)
			result.message = "%s 进入防御姿态！" % actor.display_name

		GameConstants.ACTION_SKILL:
			var skill_id: String = target_spec.get("skill_id", "")
			if skill_id.is_empty():
				result.message = "未选择技能"
				return result

			var skill_definition: Dictionary = ContentDB.get_skill_definition(skill_id)
			var skill_target_type := _normalize_target_type(
				skill_definition.get("target_type", skill_definition.get("target", "enemy_single"))
			)
			var skill_targets := _resolve_targets(session, actor, target_spec, skill_target_type)
			var target_node: Node = player_node
			if not skill_targets.is_empty() and skill_targets[0].source_node != null:
				target_node = skill_targets[0].source_node

			var skill_result: Dictionary = SkillService.use_skill(skill_id, player_node, target_node)
			result.message = skill_result.get("message", "")

		GameConstants.ACTION_ITEM:
			var item_id: String = target_spec.get("item_id", "")
			if item_id.is_empty():
				result.message = "未选择物品"
				return result
			result = _use_item_in_battle(session, actor, item_id, target_spec)

		GameConstants.ACTION_FLEE:
			if randf() < GameConstants.BASE_FLEE_CHANCE:
				result.ended = true
				result.result = "flee"
				result.message = "成功逃跑！"
			else:
				result.ended = true
				result.result = "flee_failed"
				result.message = "逃跑失败！"

		_:
			result.message = "未知行动"

	session.refresh()
	if not result.ended and session.get_active_enemy() == null:
		result.ended = true
		result.result = "victory"
		if result.message.is_empty():
			result.message = "战斗胜利！"

	return result

func execute_enemy_turn(session: BattleSession) -> Dictionary:
	var result := {"player_defeated": false, "enemy_defeated": false, "message": ""}
	if session == null:
		return result

	session.refresh()
	var actor := session.get_active_enemy()
	var target := session.get_active_player()
	if actor == null:
		result.enemy_defeated = true
		return result
	if target == null:
		result.player_defeated = true
		return result

	var enemy_node: Node = actor.source_node
	var player_node: Node = target.source_node
	if enemy_node == null or player_node == null:
		result.player_defeated = true
		return result

	if enemy_node.has_method("reset_defense_boost"):
		enemy_node.reset_defense_boost()

	var action_data: Dictionary = {}
	if enemy_node.has_method("decide_action"):
		action_data = enemy_node.decide_action(player_node)
	if action_data.is_empty():
		action_data = {"action": "attack", "target": player_node}

	var action_result := {"message": ""}
	if enemy_node.has_method("execute_action"):
		action_result = enemy_node.execute_action(action_data)
	result.message = action_result.get("message", "")

	target.set_defending(false)
	SkillService.reduce_cooldowns()
	session.round_index += 1

	session.refresh()
	result.player_defeated = session.get_active_player() == null
	result.enemy_defeated = session.get_active_enemy() == null
	return result

func _use_item_in_battle(
	session: BattleSession,
	actor: CombatantState,
	item_id: String,
	target_spec: Dictionary = {}
) -> Dictionary:
	var result := {"ended": false, "result": "", "message": ""}
	if actor == null or actor.source_node == null:
		result.message = "玩家不存在"
		return result

	if not InventoryService.has_item_id(item_id):
		result.message = "物品不存在"
		return result

	var item_data: Dictionary = InventoryService.get_item_data(item_id)
	var item_name: String = item_data.get("display_name", item_data.get("item_name", "未知物品"))
	if item_data.get("item_type", GameConstants.ITEM_TYPE_CONSUMABLE) != GameConstants.ITEM_TYPE_CONSUMABLE:
		result.message = "%s 不是消耗品" % item_name
		return result

	var targets := _resolve_targets(session, actor, target_spec, "self")
	var target_node: Node = actor.source_node
	if not targets.is_empty() and targets[0].source_node != null:
		target_node = targets[0].source_node

	var used := false
	var effect_messages: PackedStringArray = []
	if item_data.has("heal_amount") and item_data.heal_amount > 0:
		if target_node.current_health < target_node.max_health:
			target_node.heal(item_data.heal_amount)
			used = true
			effect_messages.append("恢复 %d 点生命值" % item_data.heal_amount)

	if item_data.has("restore_mana_amount") and item_data.restore_mana_amount > 0:
		if target_node.current_mana < target_node.max_mana:
			target_node.restore_mana(item_data.restore_mana_amount)
			used = true
			effect_messages.append("恢复 %d 点魔法值" % item_data.restore_mana_amount)

	if used:
		InventoryService.remove_item_by_id(item_id, 1)
		result.message = "使用 %s，%s" % [item_name, "，".join(effect_messages)]
	else:
		result.message = "%s 没有效果" % item_name

	return result

func _resolve_actor(session: BattleSession, actor_id: String, faction: String) -> CombatantState:
	if not actor_id.is_empty():
		var resolved := session.find_combatant(actor_id)
		if resolved != null and resolved.faction == faction:
			return resolved

	if faction == "player":
		return session.get_active_player()
	return session.get_active_enemy()

func _resolve_targets(
	session: BattleSession,
	actor: CombatantState,
	target_spec: Dictionary,
	default_target_type: String
) -> Array[CombatantState]:
	var resolved_spec: Dictionary = target_spec.duplicate(true)
	if not resolved_spec.has("target_type") or String(resolved_spec["target_type"]).is_empty():
		resolved_spec["target_type"] = default_target_type
	return _targeting.resolve_targets(session, actor, resolved_spec)

func _get_attack_value(actor: CombatantState) -> int:
	if actor == null:
		return 0
	if actor.source_node and actor.source_node.has_method("get_total_attack"):
		return int(actor.source_node.get_total_attack())
	return actor.attack

func _normalize_target_type(raw_target) -> String:
	match String(raw_target):
		"self":
			return "self"
		"ally", "ally_single":
			return "ally_single"
		"ally_all":
			return "ally_all"
		"enemy_all":
			return "enemy_all"
		"enemy", "enemy_single":
			return "enemy_single"
		_:
			return "enemy_single"
