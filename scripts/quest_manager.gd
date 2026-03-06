extends Node

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, objective_index: int)
signal quest_completed(quest_id: String)
signal quest_rewarded(quest_id: String)

# 任务定义库（可在游戏初始化时从配置文件加载）
var quest_database: Dictionary = {}

# 玩家任务状态
var active_quests: Dictionary = {}      # quest_id -> quest_data
var completed_quests: Array[String] = [] # 已完成但未领取奖励的任务
var rewarded_quests: Array[String] = []  # 已领取奖励的任务

# 任务定义格式示例
const QUEST_TEMPLATE = {
	"id": "",
	"name": "",
	"description": "",
	"type": "main",  # main/side/daily
	"status": "inactive",  # inactive/active/completed/rewarded
	"objectives": [],  # 见下方格式
	"rewards": {
		"experience": 0,
		"gold": 0,
		"items": []
	},
	"prerequisites": [],  # 前置任务ID列表
	"giver_npc": "",
	"reward_npc": null,  # null表示与giver相同
	"dialogue_start": [],  # 开始任务时的对话
	"dialogue_complete": [],  # 完成任务时的对话
	"dialogue_reward": []  # 领取奖励时的对话
}

# 任务目标格式
const OBJECTIVE_TEMPLATE = {
	"type": "kill",  # kill/collect/talk/location/defend
	"target": "",    # 目标ID（敌人ID/物品ID/NPC ID/场景名）
	"required": 1,
	"current": 0,
	"description": ""  # 可选，覆盖默认描述
}

func _ready() -> void:
	_initialize_quest_database()

func _initialize_quest_database() -> void:
	# 示例任务：击败史莱姆
	quest_database["quest_001"] = {
		"id": "quest_001",
		"name": "初出茅庐",
		"description": "村庄附近出现了史莱姆，去击败3只史莱姆保护村民。",
		"type": "main",
		"objectives": [
			{
				"type": "kill",
				"target": "slime",
				"required": 3,
				"current": 0,
				"description": "击败史莱姆 (0/3)"
			}
		],
		"rewards": {
			"experience": 100,
			"gold": 50,
			"items": [
				{"id": "health_potion", "quantity": 3}
			]
		},
		"prerequisites": [],
		"giver_npc": "villager",
		"reward_npc": null,
		"dialogue_start": ["村庄附近出现了史莱姆！", "你能去击败3只史莱姆吗？"],
		"dialogue_complete": ["你击败了史莱姆！谢谢你！"],
		"dialogue_reward": ["这是给你的奖励。"]
	}
	
	# 示例任务：与商人对话
	quest_database["quest_002"] = {
		"id": "quest_002",
		"name": "神秘商人",
		"description": "去找神秘商人，他可能有重要的消息。",
		"type": "main",
		"objectives": [
			{
				"type": "talk",
				"target": "merchant",
				"required": 1,
				"current": 0,
				"description": "与神秘商人对话"
			}
		],
		"rewards": {
			"experience": 50,
			"gold": 30,
			"items": [
				{"id": "iron_sword", "quantity": 1}
			]
		},
		"prerequisites": ["quest_001"],
		"giver_npc": "villager",
		"reward_npc": "merchant",
		"dialogue_start": ["神秘商人正在寻找勇士。", "去和他谈谈吧。"],
		"dialogue_complete": ["你来了。我等你很久了。"],
		"dialogue_reward": ["这把铁剑送给你。"]
	}

# 检查是否可以开始任务
func can_start_quest(quest_id: String) -> bool:
	if not quest_database.has(quest_id):
		return false
	if active_quests.has(quest_id) or completed_quests.has(quest_id) or rewarded_quests.has(quest_id):
		return false
	
	var quest_def = quest_database[quest_id]
	for prereq in quest_def.get("prerequisites", []):
		if not rewarded_quests.has(prereq):
			return false
	return true

# 开始任务
func start_quest(quest_id: String) -> bool:
	if not can_start_quest(quest_id):
		return false
	
	var quest_def = quest_database[quest_id].duplicate(true)
	quest_def["status"] = "active"
	active_quests[quest_id] = quest_def
	
	quest_started.emit(quest_id)
	print("任务开始: ", quest_def["name"])
	return true

# 更新任务进度
func update_quest(quest_id: String, objective_type: String, target: String, amount: int = 1) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	var updated = false
	
	for i in range(quest["objectives"].size()):
		var obj = quest["objectives"][i]
		if obj["type"] == objective_type and obj["target"] == target:
			if obj["current"] < obj["required"]:
				obj["current"] = min(obj["current"] + amount, obj["required"])
				# 更新描述中的进度
				obj["description"] = _generate_objective_description(obj)
				updated = true
				quest_updated.emit(quest_id, i)
				print("任务进度更新: %s (%s)" % [quest["name"], obj["description"]])
				break
	
	if updated and _is_quest_complete(quest):
		_complete_quest(quest_id)

# 更新所有相关任务的进度（简化调用）
func update_all_quests(objective_type: String, target: String, amount: int = 1) -> void:
	for quest_id in active_quests.keys():
		update_quest(quest_id, objective_type, target, amount)

# 检查任务是否完成
func _is_quest_complete(quest: Dictionary) -> bool:
	for obj in quest["objectives"]:
		if obj["current"] < obj["required"]:
			return false
	return true

# 完成任务
func _complete_quest(quest_id: String) -> void:
	if not active_quests.has(quest_id):
		return
	
	var quest = active_quests[quest_id]
	quest["status"] = "completed"
	
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	
	quest_completed.emit(quest_id)
	print("任务完成: ", quest["name"])

# 领取奖励
func reward_quest(quest_id: String) -> bool:
	if not completed_quests.has(quest_id):
		return false
	
	var quest_def = quest_database[quest_id]
	var rewards = quest_def.get("rewards", {})
	
	# 给予经验
	if rewards.has("experience") and rewards["experience"] > 0:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("add_experience"):
			player.add_experience(rewards["experience"])
	
	# 给予金币
	if rewards.has("gold") and rewards["gold"] > 0:
		InventoryManager.add_gold(rewards["gold"])
	
	# 给予物品
	if rewards.has("items"):
		for item_reward in rewards["items"]:
			var item_data = _get_item_data_by_id(item_reward["id"])
			if item_data:
				InventoryManager.add_item(item_data, item_reward["quantity"])
	
	completed_quests.erase(quest_id)
	rewarded_quests.append(quest_id)
	
	quest_rewarded.emit(quest_id)
	print("领取奖励: ", quest_def["name"])
	return true

# 获取物品数据（临时方法，应该从ItemDatabase获取）
func _get_item_data_by_id(item_id: String) -> Dictionary:
	# 基础物品定义
	var items = {
		"health_potion": {
			"item_name": "生命药水",
			"item_type": 0,  # CONSUMABLE
			"heal_amount": 30,
			"price": 20,
			"stackable": true
		},
		"mana_potion": {
			"item_name": "魔法药水",
			"item_type": 0,
			"restore_mana_amount": 20,
			"price": 15,
			"stackable": true
		},
		"iron_sword": {
			"item_name": "铁剑",
			"item_type": 1,  # EQUIPMENT
			"equipment_slot": 1,  # WEAPON
			"attack": 5,
			"price": 100,
			"stackable": false
		}
	}
	return items.get(item_id, {})

# 获取进行中的任务
func get_active_quests() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for quest_id in active_quests:
		result.append(active_quests[quest_id])
	return result

# 获取特定任务
func get_quest(quest_id: String) -> Dictionary:
	if active_quests.has(quest_id):
		return active_quests[quest_id]
	if quest_database.has(quest_id):
		return quest_database[quest_id]
	return {}

# 检查任务状态
func get_quest_status(quest_id: String) -> String:
	if active_quests.has(quest_id):
		return "active"
	if completed_quests.has(quest_id):
		return "completed"
	if rewarded_quests.has(quest_id):
		return "rewarded"
	return "inactive"

# 生成任务目标描述
func _generate_objective_description(obj: Dictionary) -> String:
	var desc = obj.get("description", "")
	if desc.is_empty():
		match obj["type"]:
			"kill":
				desc = "击败 %s" % obj["target"]
			"collect":
				desc = "收集 %s" % obj["target"]
			"talk":
				desc = "与 %s 对话" % obj["target"]
			"location":
				desc = "到达 %s" % obj["target"]
	
	return "%s (%d/%d)" % [desc, obj["current"], obj["required"]]

# 存档数据
func get_save_data() -> Dictionary:
	return {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(),
		"rewarded_quests": rewarded_quests.duplicate()
	}

# 读档数据
func load_save_data(data: Dictionary) -> void:
	active_quests.clear()
	completed_quests.clear()
	rewarded_quests.clear()
	
	if data.has("active_quests"):
		active_quests = data["active_quests"].duplicate(true)
	if data.has("completed_quests"):
		# 将读取的数组转换为 String 类型
		var loaded_completed = data["completed_quests"]
		for quest_id in loaded_completed:
			if quest_id is String:
				completed_quests.append(quest_id)
	if data.has("rewarded_quests"):
		# 将读取的数组转换为 String 类型
		var loaded_rewarded = data["rewarded_quests"]
		for quest_id in loaded_rewarded:
			if quest_id is String:
				rewarded_quests.append(quest_id)
	
	print("任务数据已加载，进行中的任务: ", active_quests.size())

# 添加新任务定义（用于扩展）
func add_quest_definition(quest_def: Dictionary) -> void:
	if quest_def.has("id"):
		quest_database[quest_def["id"]] = quest_def.duplicate(true)

# 重置所有任务（调试用）
func reset_all_quests() -> void:
	active_quests.clear()
	completed_quests.clear()
	rewarded_quests.clear()
	print("所有任务已重置")
