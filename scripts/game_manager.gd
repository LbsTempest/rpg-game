extends Node

signal game_saved
signal game_loaded
signal new_game_started

const SAVE_FILE_PATH := "user://save_game.json"
const SAVE_VERSION := "1.1"  # 存档版本，用于兼容性检查

var current_scene_name: String = ""
var is_paused: bool = false
var is_new_game: bool = true  # 标记是否新游戏
var is_inventory_open: bool = false  # 物品栏是否打开

func _ready() -> void:
	# 不再自动加载存档，玩家需要手动选择新游戏或加载存档
	print("GameManager 初始化完成，等待玩家选择新游戏或加载存档")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	if event.is_action_pressed("ui_focus_next"):
		if Input.is_action_pressed("ui_accept"):
			save_game()

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused

# 开始新游戏
func start_new_game() -> void:
	is_new_game = true
	current_scene_name = "main"
	
	# 重置所有管理器数据
	_reset_all_managers()
	
	new_game_started.emit()
	print("开始新游戏")

# 重置所有管理器
func _reset_all_managers() -> void:
	# 重置任务
	if QuestManager:
		QuestManager.reset_all_quests()
	
	# 重置商店库存
	if ShopManager:
		ShopManager.shop_inventories.clear()
	
	# 重置技能
	if SkillManager:
		SkillManager.reset_skills()
	
	# 重置背包
	if InventoryManager:
		InventoryManager.item_quantities.clear()
		InventoryManager.item_definitions.clear()
		InventoryManager.gold = 0
		# 重新添加初始物品
		_give_starting_items()
	
	# 重置敌人
	if EnemyManager:
		EnemyManager.reset_all_enemies()
	
	print("所有管理器已重置")

# 给予初始物品
func _give_starting_items() -> void:
	# 初始物品数据（使用统一的Dictionary格式）
	var starting_items = [
		{
			"item_id": "health_potion",
			"item_name": "生命药水",
			"item_type": 0,
			"heal_amount": 30,
			"price": 20,
			"stackable": true,
			"max_stack": 99
		},
		{
			"item_id": "iron_sword",
			"item_name": "铁剑",
			"item_type": 1,
			"equipment_slot": 1,
			"attack": 5,
			"price": 100,
			"stackable": false,
			"max_stack": 1
		},
		{
			"item_id": "leather_armor",
			"item_name": "皮甲",
			"item_type": 1,
			"equipment_slot": 2,
			"defense": 3,
			"price": 80,
			"stackable": false,
			"max_stack": 1
		}
	]
	
	# 添加物品到背包
	InventoryManager.add_item(starting_items[0], 3)  # 3瓶生命药水
	InventoryManager.add_item(starting_items[1], 1)  # 1把铁剑
	InventoryManager.add_item(starting_items[2], 1)  # 1件皮甲
	
	# 给予初始金币
	InventoryManager.add_gold(100)

# 保存游戏
func save_game() -> void:
	var enemy_data = EnemyManager.get_save_data()
	print("保存敌人数据: ", enemy_data.size(), " 个敌人")
	for enemy_id in enemy_data:
		var state = enemy_data[enemy_id]
		print("  - ", enemy_id, ": 存活=", state.get("is_alive", true))
	
	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"current_scene": current_scene_name,
		"player": get_player_save_data(),
		"inventory": InventoryManager.get_save_data(),
		"quests": QuestManager.get_save_data(),
		"shop_inventories": ShopManager.get_save_data(),
		"skills": SkillManager.get_save_data(),
		"enemies": enemy_data
	}
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		game_saved.emit()
		print("游戏保存成功")
	else:
		push_error("无法打开存档文件进行写入")

func get_player_save_data() -> Dictionary:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		var data = player.get_save_data()
		print("GameManager: 保存玩家位置: (", data.position.x, ", ", data.position.y, ")")
		return data
	return {}

# 加载游戏（手动调用）
func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("未找到存档文件")
		return false
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		push_error("无法打开存档文件")
		return false
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_string)
	if error != OK:
		push_error("存档文件解析错误: " + json.get_error_message())
		return false
	
	var save_data: Dictionary = json.data
	
	# 检查版本
	var version = save_data.get("version", "1.0")
	if version != SAVE_VERSION:
		print("存档版本不匹配: %s != %s，尝试兼容加载" % [version, SAVE_VERSION])
	
	apply_save_data(save_data)
	is_new_game = false
	game_loaded.emit()
	print("游戏加载成功")
	return true

func apply_save_data(data: Dictionary) -> void:
	# 加载场景
	if data.has("current_scene"):
		current_scene_name = data.current_scene
	
	# 加载玩家数据
	if data.has("player"):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.load_save_data(data.player)
	
	# 加载背包数据
	if data.has("inventory"):
		InventoryManager.load_save_data(data.inventory)
	
	# 加载任务数据
	if data.has("quests"):
		QuestManager.load_save_data(data.quests)
	else:
		# 旧版本存档没有任务数据
		QuestManager.reset_all_quests()
	
	# 加载商店数据
	if data.has("shop_inventories"):
		ShopManager.load_save_data(data.shop_inventories)
	else:
		ShopManager.shop_inventories.clear()
	
	# 加载技能数据
	if data.has("skills"):
		SkillManager.load_save_data(data.skills)
	else:
		SkillManager.reset_skills()
	
	# 加载敌人数据
	if data.has("enemies"):
		print("从存档加载敌人数据: ", data.enemies.size(), " 个敌人")
		for enemy_id in data.enemies:
			var state = data.enemies[enemy_id]
			print("  - ", enemy_id, ": 存活=", state.get("is_alive", true))
		EnemyManager.load_save_data(data.enemies)
	else:
		print("存档中没有敌人数据")
		EnemyManager.reset_all_enemies()

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("存档已删除")

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func change_scene(scene_path: String) -> void:
	current_scene_name = scene_path.get_file().get_basename()
	get_tree().change_scene_to_file(scene_path)
