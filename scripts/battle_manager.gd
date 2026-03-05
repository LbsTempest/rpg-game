extends Node

signal battle_started(enemy: Node2D)
signal battle_ended(result: String, rewards: Dictionary)
signal turn_changed(is_player_turn: bool)
signal battle_log(message: String)

const BATTLE_SCENE_PATH := "res://scenes/battle_scene.tscn"

var is_in_battle: bool = false
var current_enemy: Node2D = null
var player: Node = null

var _battle_scene: Node = null

func start_battle(enemy: Node2D) -> void:
	if is_in_battle:
		return
	
	is_in_battle = true
	current_enemy = enemy
	player = get_tree().get_first_node_in_group("player")
	
	# 暂停游戏主场景
	get_tree().paused = true
	
	# 隐藏主UI
	var main_ui = get_tree().get_first_node_in_group("ui")
	if main_ui:
		main_ui.visible = false
	
	# 加载战斗场景
	var battle_scene := preload(BATTLE_SCENE_PATH).instantiate()
	_battle_scene = battle_scene
	# 确保战斗场景在暂停时仍能处理输入
	battle_scene.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(battle_scene)
	
	# 初始化战斗
	battle_scene.initialize(player, enemy)
	battle_scene.action_selected.connect(_on_player_action)
	battle_scene.flee_requested.connect(_on_flee_attempt)
	
	battle_started.emit(enemy)
	battle_log.emit("战斗开始！遭遇了 %s！" % enemy.enemy_name)
	
	# 开始第一回合
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
	
	# 清理战斗场景
	if _battle_scene:
		_battle_scene.queue_free()
		_battle_scene = null
	
	is_in_battle = false
	current_enemy = null
	
	# 恢复游戏
	get_tree().paused = false
	
	# 显示主UI
	var main_ui = get_tree().get_first_node_in_group("ui")
	if main_ui:
		main_ui.visible = true
	
	battle_ended.emit(result, rewards)

func _start_turn() -> void:
	if not is_in_battle or not player or not current_enemy:
		return
	
	if current_enemy.is_alive and player.current_health > 0:
		turn_changed.emit(true)
		battle_log.emit("玩家回合 - 请选择行动")

func _on_player_action(action: String) -> void:
	if not is_in_battle:
		return
	
	var result := _execute_player_action(action)
	battle_log.emit(result.message)
	
	if result.ended:
		end_battle(result.result)
		return
	
	# 敌人回合
	_start_enemy_turn()

func _execute_player_action(action: String) -> Dictionary:
	var result := {"ended": false, "result": "", "message": ""}
	
	match action:
		"attack":
			var damage: int = player.get_total_attack()
			if current_enemy.has_method("take_damage"):
				current_enemy.take_damage(damage)
			var enemy_name: String = current_enemy.enemy_name if "enemy_name" in current_enemy else "怪物"
			result.message = "你对 %s 造成 %d 点伤害！" % [enemy_name, damage]
			
			var is_alive: bool = current_enemy.is_alive if "is_alive" in current_enemy else true
			if not is_alive:
				result.ended = true
				result.result = "victory"
			
		"defend":
			player.defense += 5  # 临时增加防御
			result.message = "你进入防御姿态，防御力提升！"
		
		"skill":
			# 使用第一个可用技能作为示例
			var skills: Array[Dictionary] = SkillManager.get_learned_skills()
			if skills.size() > 0:
				var first_skill: Dictionary = skills[0]
				var skill_id: String = first_skill.get("skill_id", "")
				var skill_result: Dictionary = SkillManager.use_skill(skill_id, player, current_enemy)
				result.message = skill_result.message
				
				if skill_result.success:
					# 检查敌人是否死亡
					var is_alive: bool = current_enemy.is_alive if "is_alive" in current_enemy else true
					if not is_alive:
						result.ended = true
						result.result = "victory"
					
					# 减少技能冷却
					SkillManager.reduce_cooldowns()
			else:
				result.message = "没有学会任何技能"
		
		"item":
			result.message = "请使用物品栏"
		
		"flee":
			var flee_chance := 0.5
			if randf() < flee_chance:
				result.ended = true
				result.result = "flee"
			else:
				result.message = "逃跑失败！"
				result.ended = true
				result.result = "flee_failed"
	
	return result

func _start_enemy_turn() -> void:
	if not is_in_battle:
		return
	
	turn_changed.emit(false)
	var enemy_name: String = current_enemy.enemy_name if "enemy_name" in current_enemy else "怪物"
	battle_log.emit("%s 的回合..." % enemy_name)
	
	# 敌人AI决策
	var action_data: Dictionary = current_enemy.call("decide_action", player) if current_enemy.has_method("decide_action") else {"action": "attack", "target": player}
	var result: Dictionary = current_enemy.call("execute_action", action_data) if current_enemy.has_method("execute_action") else {"success": true, "damage": 0, "message": "攻击"}
	
	battle_log.emit(result.message)
	
	# 检查玩家是否死亡
	if player.current_health <= 0:
		end_battle("defeat")
		return
	
	# 返回玩家回合
	_start_turn()

func _on_flee_attempt() -> void:
	_on_player_action("flee")

func _handle_player_defeat() -> void:
	# 玩家死亡处理：恢复少量HP，传送回起点
	player.current_health = max(1, player.max_health * 0.3)
	player.position = Vector2(128, 128)
	player.health_changed.emit(player.current_health, player.max_health)
	battle_log.emit("你被打败了... 已恢复部分生命值")
