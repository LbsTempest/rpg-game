extends Node

signal battle_started(enemy: Node2D)
signal battle_ended(result: String, rewards: Dictionary)
signal turn_changed(is_player_turn: bool)
signal battle_log(message: String)

const BATTLE_SCENE_PATH := GameConstants.SCENE_BATTLE

var is_in_battle: bool = false
var current_enemy: Node2D = null
var player: Node = null

var _battle_scene: Node = null
var _is_player_defending: bool = false

func start_battle(enemy: Node2D) -> void:
	if is_in_battle:
		return
	
	is_in_battle = true
	current_enemy = enemy
	player = Utils.get_group_node("player")
	_is_player_defending = false
	
	get_tree().paused = true
	
	var main_ui = Utils.get_group_node("ui")
	if main_ui:
		main_ui.visible = false
	
	var battle_scene = preload(BATTLE_SCENE_PATH).instantiate()
	_battle_scene = battle_scene
	battle_scene.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(battle_scene)
	
	battle_scene.initialize(player, enemy)
	battle_scene.action_selected.connect(_on_player_action)
	battle_scene.flee_requested.connect(_on_flee_attempt)
	battle_scene.skill_selected.connect(_on_skill_selected)
	battle_scene.item_used.connect(_on_item_used)
	UIRouter.register_modal("battle", Callable(), 100, true)
	
	battle_started.emit(enemy)
	battle_log.emit("战斗开始！遭遇了 %s！" % enemy.enemy_name)
	GameEvents.emit_domain_event("battle_started", {"enemy_name": enemy.enemy_name})
	
	_start_turn()

func end_battle(result: String) -> void:
	if not is_in_battle:
		return
	
	var rewards := {}
	
	match result:
		"victory":
			rewards = {
				"experience": current_enemy.experience_reward,
				"gold": current_enemy.gold_reward
			}
			player.add_experience(current_enemy.experience_reward)
			InventoryManager.add_gold(current_enemy.gold_reward)
			QuestManager.update_all_quests(GameConstants.OBJECTIVE_KILL, current_enemy.enemy_name, 1)
			battle_log.emit("战斗胜利！获得 %d 经验值和 %d 金币！" % [current_enemy.experience_reward, current_enemy.gold_reward])
		
		"defeat":
			battle_log.emit("战斗失败...")
			_handle_player_defeat()
		
		"flee":
			battle_log.emit("成功逃跑！")
		
		"flee_failed":
			battle_log.emit("逃跑失败！")
			_start_enemy_turn()
			return
	
	_cleanup_battle()
	battle_ended.emit(result, rewards)
	GameEvents.emit_domain_event("battle_ended", {"result": result, "rewards": rewards})

func _cleanup_battle() -> void:
	if _battle_scene:
		_battle_scene.queue_free()
		_battle_scene = null
	
	is_in_battle = false
	current_enemy = null
	
	get_tree().paused = false
	UIRouter.unregister_modal("battle")
	
	var main_ui = Utils.get_group_node("ui")
	if main_ui:
		main_ui.visible = true

func _start_turn() -> void:
	if not is_in_battle:
		return
	
	if current_enemy.is_alive and player.current_health > 0:
		_is_player_defending = false
		turn_changed.emit(true)
		battle_log.emit("玩家回合 - 请选择行动")

func _on_player_action(action: String, data: Dictionary = {}) -> void:
	if not is_in_battle:
		return
	
	var result = _execute_player_action(action, data)
	battle_log.emit(result.message)
	
	if result.ended:
		end_battle(result.result)
		return
	
	_start_enemy_turn()

func _execute_player_action(action: String, data: Dictionary = {}) -> Dictionary:
	var result = {"ended": false, "result": "", "message": ""}
	
	match action:
		GameConstants.ACTION_ATTACK:
			var damage: int = player.get_total_attack()
			current_enemy.take_damage(damage)
			result.message = "你对 %s 造成 %d 点伤害！" % [current_enemy.enemy_name, damage]
			
			if not current_enemy.is_alive:
				result.ended = true
				result.result = "victory"
		
		GameConstants.ACTION_DEFEND:
			_is_player_defending = true
			result.message = "你进入防御姿态，防御力提升！"
		
		GameConstants.ACTION_SKILL:
			var skill_id = data.get("skill_id", "")
			if skill_id.is_empty():
				result.message = "未选择技能"
				return result
			
			var skill_result = SkillManager.use_skill(skill_id, player, current_enemy)
			result.message = skill_result.message
			
			if skill_result.success:
				if not current_enemy.is_alive:
					result.ended = true
					result.result = "victory"
				SkillManager.reduce_cooldowns()
		
		GameConstants.ACTION_ITEM:
			var item_id = data.get("item_id", "")
			if item_id.is_empty():
				result.message = "未选择物品"
				return result
			
			result = _use_item_in_battle(item_id)
		
		GameConstants.ACTION_FLEE:
			if randf() < GameConstants.BASE_FLEE_CHANCE:
				result.ended = true
				result.result = "flee"
			else:
				result.message = "逃跑失败！"
				result.ended = true
				result.result = "flee_failed"
	
	return result

func _use_item_in_battle(item_id: String) -> Dictionary:
	var result = {"ended": false, "result": "", "message": ""}
	
	if not InventoryManager.has_item_id(item_id):
		result.message = "物品不存在"
		return result
	
	var item_data = InventoryManager.get_item_data(item_id)
	var item_name = item_data.get("item_name", "未知物品")
	
	if item_data.get("item_type", GameConstants.ITEM_TYPE_CONSUMABLE) != GameConstants.ITEM_TYPE_CONSUMABLE:
		result.message = "%s 不是消耗品" % item_name
		return result
	
	var used = false
	
	if item_data.has("heal_amount") and item_data.heal_amount > 0:
		if player.current_health >= player.max_health:
			result.message = "生命值已满"
			return result
		player.heal(item_data.heal_amount)
		used = true
		result.message = "使用 %s，恢复 %d 点生命值" % [item_name, item_data.heal_amount]
	
	if item_data.has("restore_mana_amount") and item_data.restore_mana_amount > 0:
		if player.current_mana >= player.max_mana:
			result.message = "魔法值已满"
			return result
		player.restore_mana(item_data.restore_mana_amount)
		used = true
		result.message = "使用 %s，恢复 %d 点魔法值" % [item_name, item_data.restore_mana_amount]
	
	if used:
		InventoryManager.remove_item_by_id(item_id, 1)
	else:
		result.message = "%s 没有效果" % item_name
	
	return result

func _on_skill_selected(skill_id: String) -> void:
	_on_player_action(GameConstants.ACTION_SKILL, {"skill_id": skill_id})

func _on_item_used(item_id: String) -> void:
	_on_player_action(GameConstants.ACTION_ITEM, {"item_id": item_id})

func _start_enemy_turn() -> void:
	if not is_in_battle:
		return
	
	player.set_defending(false)
	
	turn_changed.emit(false)
	battle_log.emit("%s 的回合..." % current_enemy.enemy_name)
	
	current_enemy.reset_defense_boost()
	
	var action_data = current_enemy.decide_action(player)
	var result = current_enemy.execute_action(action_data)
	
	battle_log.emit(result.message)
	
	if player.current_health <= 0:
		end_battle("defeat")
		return
	
	_start_turn()

func _on_flee_attempt() -> void:
	_on_player_action(GameConstants.ACTION_FLEE, {})

func _handle_player_defeat() -> void:
	player.current_health = max(1, int(player.max_health * 0.3))
	player.position = Vector2(128, 128)
	player.health_changed.emit(player.current_health, player.max_health)
	battle_log.emit("你被打败了... 已恢复部分生命值")
