class_name BattleResolver
extends RefCounted

var _targeting := TargetingService.new()

func execute_player_action(session: BattleSession, action_id: String, data: Dictionary = {}) -> Dictionary:
	var result := {"ended": false, "result": "", "message": ""}
	if session == null:
		result.message = "battle_session_missing"
		return result

	session.refresh()
	var actor := session.get_active_player()
	var target := session.get_active_enemy()
	if actor == null or target == null:
		result.ended = true
		result.result = "defeat"
		result.message = "战斗结束"
		return result

	var player_node: Node = actor.source_node
	var enemy_node: Node = target.source_node

	match action_id:
		GameConstants.ACTION_ATTACK:
			var damage: int = player_node.get_total_attack()
			enemy_node.take_damage(damage)
			result.message = "你对 %s 造成 %d 点伤害！" % [target.display_name, damage]
		GameConstants.ACTION_DEFEND:
			session.player_defend_active = true
			actor.set_defending(true)
			result.message = "你进入防御姿态，防御力提升！"
		GameConstants.ACTION_SKILL:
			var skill_id: String = data.get("skill_id", "")
			if skill_id.is_empty():
				result.message = "未选择技能"
				return result
			var skill_result: Dictionary = SkillManager.use_skill(skill_id, player_node, enemy_node)
			result.message = skill_result.get("message", "")
		GameConstants.ACTION_ITEM:
			var item_id: String = data.get("item_id", "")
			if item_id.is_empty():
				result.message = "未选择物品"
				return result
			result = _use_item_in_battle(player_node, item_id)
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

	if session.player_defend_active:
		target.set_defending(true)

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

	session.player_defend_active = false
	target.set_defending(false)
	SkillManager.reduce_cooldowns()
	session.round_index += 1

	session.refresh()
	result.player_defeated = session.get_active_player() == null
	result.enemy_defeated = session.get_active_enemy() == null
	return result

func _use_item_in_battle(player_node: Node, item_id: String) -> Dictionary:
	var result := {"ended": false, "result": "", "message": ""}

	if not InventoryManager.has_item_id(item_id):
		result.message = "物品不存在"
		return result

	var item_data: Dictionary = InventoryManager.get_item_data(item_id)
	var item_name: String = item_data.get("item_name", "未知物品")
	if item_data.get("item_type", GameConstants.ITEM_TYPE_CONSUMABLE) != GameConstants.ITEM_TYPE_CONSUMABLE:
		result.message = "%s 不是消耗品" % item_name
		return result

	var used := false
	if item_data.has("heal_amount") and item_data.heal_amount > 0:
		if player_node.current_health < player_node.max_health:
			player_node.heal(item_data.heal_amount)
			used = true
			result.message = "使用 %s，恢复 %d 点生命值" % [item_name, item_data.heal_amount]

	if item_data.has("restore_mana_amount") and item_data.restore_mana_amount > 0:
		if player_node.current_mana < player_node.max_mana:
			player_node.restore_mana(item_data.restore_mana_amount)
			used = true
			result.message = "使用 %s，恢复 %d 点魔法值" % [item_name, item_data.restore_mana_amount]

	if used:
		InventoryManager.remove_item_by_id(item_id, 1)
	else:
		result.message = "%s 没有效果" % item_name

	return result
