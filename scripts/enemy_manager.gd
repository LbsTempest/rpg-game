extends Node

# 存储所有敌人的状态
var enemy_states: Dictionary = {}  # enemy_id -> enemy_data

func _ready() -> void:
	print("EnemyManager 初始化完成")

# 注册敌人（在敌人 _ready 时调用）
func register_enemy(enemy: Node) -> void:
	var enemy_id = _get_enemy_id(enemy)
	
	print("EnemyManager: 注册敌人 ", enemy_id)
	print("  当前存档中的敌人: ", enemy_states.keys())
	
	# 如果有存档状态，恢复它
	if enemy_states.has(enemy_id):
		var state = enemy_states[enemy_id]
		print("  找到匹配的存档状态: ", state)
		_load_enemy_state(enemy, state)
		print("  ✓ 恢复敌人状态: ", enemy_id, " 存活=", state.get("is_alive", true))
	else:
		# 新敌人，保存初始状态
		_save_enemy_state(enemy)
		print("  ✓ 注册新敌人: ", enemy_id)

# 保存单个敌人状态
func _save_enemy_state(enemy: Node) -> void:
	if not enemy.has_method("get_save_data"):
		print("    ✗ 敌人没有 get_save_data 方法")
		return
	
	var enemy_id = _get_enemy_id(enemy)
	var state = enemy.get_save_data()
	var is_alive = enemy.is_alive if "is_alive" in enemy else true
	state["is_alive"] = is_alive
	enemy_states[enemy_id] = state
	print("    ✓ 保存敌人 ", enemy_id, " 状态: 存活=", is_alive, " HP=", state.get("current_health", "unknown"))

# 加载单个敌人状态
func _load_enemy_state(enemy: Node, state: Dictionary) -> void:
	if not enemy.has_method("load_save_data"):
		print("    ✗ 敌人没有 load_save_data 方法")
		return
	
	enemy.load_save_data(state)
	print("    ✓ 已调用 load_save_data")
	
	# 恢复存活状态（backup，以防 load_save_data 没有处理）
	if state.has("is_alive"):
		var is_alive = state.is_alive
		enemy.is_alive = is_alive
		print("    - 设置 is_alive = ", is_alive)
		if not is_alive:
			# 如果敌人已死亡，隐藏它
			enemy.visible = false
			enemy.process_mode = Node.PROCESS_MODE_DISABLED
			print("    - 已隐藏死亡的敌人")

# 更新敌人状态（在敌人死亡时调用）
func update_enemy_state(enemy: Node) -> void:
	_save_enemy_state(enemy)

# 获取敌人唯一ID
func _get_enemy_id(enemy: Node) -> String:
	# 使用敌人名称 + 出生位置作为唯一ID（比路径更稳定）
	var enemy_name = enemy.enemy_name if "enemy_name" in enemy else "Enemy"
	var spawn_pos = enemy.spawn_position if "spawn_position" in enemy else Vector2.ZERO
	return "%s_%.0f_%.0f" % [enemy_name, spawn_pos.x, spawn_pos.y]

# 保存所有敌人状态到字典
func get_save_data() -> Dictionary:
	# 重新收集当前所有敌人的状态
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	print("EnemyManager: 发现 ", all_enemies.size(), " 个敌人，开始保存位置...")
	for enemy in all_enemies:
		if enemy.has_method("get_save_data"):
			_save_enemy_state(enemy)
			var pos = enemy.position
			print("  - 保存敌人位置: (", pos.x, ", ", pos.y, ")")
	
	return enemy_states.duplicate(true)

# 加载所有敌人状态
func load_save_data(data: Dictionary) -> void:
	enemy_states.clear()
	if data.size() > 0:
		enemy_states = data.duplicate(true)
		print("EnemyManager: 加载敌人状态，共 ", enemy_states.size(), " 个敌人")
		for enemy_id in enemy_states:
			var state = enemy_states[enemy_id]
			print("  - 已加载: ", enemy_id, " 存活=", state.get("is_alive", true))
	else:
		print("EnemyManager: 没有敌人存档数据")

# 重置所有敌人（新游戏）
func reset_all_enemies() -> void:
	enemy_states.clear()
	print("所有敌人状态已重置")
