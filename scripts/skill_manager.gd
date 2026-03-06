extends Node

signal skill_learned(skill_id: String)
signal skill_cooldown_updated(skill_id: String, cooldown: int)

# 技能数据结构
# skill_id: {
#   "name": String,
#   "description": String,
#   "mana_cost": int,
#   "damage": int,
#   "heal": int,
#   "target": String,  # "enemy", "self", "all_enemies"
#   "cooldown": int    # 冷却回合数
# }

var available_skills: Dictionary = {
	"fireball": {
		"name": "火球术",
		"description": "发射火球攻击敌人，造成魔法伤害",
		"mana_cost": 10,
		"damage": 20,
		"heal": 0,
		"target": "enemy",
		"cooldown": 0
	},
	"heal": {
		"name": "治愈术",
		"description": "恢复生命值",
		"mana_cost": 15,
		"damage": 0,
		"heal": 30,
		"target": "self",
		"cooldown": 2
	},
	"slash": {
		"name": "重斩",
		"description": "强力的物理攻击",
		"mana_cost": 5,
		"damage": 15,
		"heal": 0,
		"target": "enemy",
		"cooldown": 1
	}
}

# 玩家已学习的技能
var learned_skills: Array[String] = []

# 技能冷却计数（当前回合剩余冷却）
var skill_cooldowns: Dictionary = {}

func _ready() -> void:
	# 默认学会一些基础技能
	reset_skills()

# 重置技能（新游戏时使用）
func reset_skills() -> void:
	learned_skills.clear()
	skill_cooldowns.clear()
	
	# 初始学会的技能
	learn_skill("slash")
	learn_skill("fireball")
	
	print("技能已重置，初始技能: ", learned_skills)

func learn_skill(skill_id: String) -> bool:
	if not available_skills.has(skill_id):
		return false
	
	if skill_id in learned_skills:
		return false
	
	learned_skills.append(skill_id)
	skill_cooldowns[skill_id] = 0
	skill_learned.emit(skill_id)
	print("学会技能: ", available_skills[skill_id]["name"])
	return true

func can_use_skill(skill_id: String, player: Node) -> Dictionary:
	var result := {"can_use": false, "reason": ""}
	
	if not skill_id in learned_skills:
		result.reason = "未学会此技能"
		return result
	
	if not available_skills.has(skill_id):
		result.reason = "技能不存在"
		return result
	
	var skill: Dictionary = available_skills[skill_id]
	
	# 检查冷却
	if skill_cooldowns.get(skill_id, 0) > 0:
		result.reason = "技能冷却中（还剩 %d 回合）" % skill_cooldowns[skill_id]
		return result
	
	# 检查魔法值
	var mana_cost: int = skill.get("mana_cost", 0)
	if player.current_mana < mana_cost:
		result.reason = "魔法值不足（需要 %d）" % mana_cost
		return result
	
	result.can_use = true
	return result

func use_skill(skill_id: String, player: Node, target = null) -> Dictionary:
	var result := {"success": false, "message": ""}
	
	var check: Dictionary = can_use_skill(skill_id, player)
	if not check.can_use:
		result.message = check.reason
		return result
	
	var skill: Dictionary = available_skills[skill_id]
	
	# 扣除魔法值
	var mana_cost: int = skill.get("mana_cost", 0)
	player.use_mana(mana_cost)
	
	# 设置冷却
	var cooldown: int = skill.get("cooldown", 0)
	if cooldown > 0:
		skill_cooldowns[skill_id] = cooldown
		skill_cooldown_updated.emit(skill_id, cooldown)
	
	# 执行效果
	var base_damage: int = skill.get("damage", 0)
	var heal: int = skill.get("heal", 0)
	var skill_name: String = skill.get("name", skill_id)
	var skill_id_str: String = skill_id
	
	# 伤害成长计算
	var final_damage: int = base_damage
	if base_damage > 0:
		# 物理技能（重斩）：根据攻击力加成
		if skill_id_str == "slash":
			var attack_bonus: int = player.attack / 2  # 50%攻击力加成
			final_damage = base_damage + attack_bonus
		# 魔法技能（火球术）：根据等级加成
		elif skill_id_str == "fireball":
			var level_bonus: int = player.level * 3  # 每级+3伤害
			final_damage = base_damage + level_bonus
		
		if target and target.has_method("take_damage"):
			target.take_damage(final_damage)
			result.message = "使用 %s 造成 %d 点伤害！" % [skill_name, final_damage]
	elif heal > 0:
		# 治疗技能根据等级加成
		var heal_bonus: int = player.level * 2  # 每级+2治疗量
		var final_heal: int = heal + heal_bonus
		player.heal(final_heal)
		result.message = "使用 %s 恢复 %d 点生命！" % [skill_name, final_heal]
	else:
		result.message = "使用 %s" % skill_name
	
	result.success = true
	return result

func reduce_cooldowns() -> void:
	"""每回合结束调用，减少所有技能冷却"""
	for skill_id in skill_cooldowns:
		if skill_cooldowns[skill_id] > 0:
			skill_cooldowns[skill_id] -= 1
			skill_cooldown_updated.emit(skill_id, skill_cooldowns[skill_id])

func get_learned_skills() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in learned_skills:
		if available_skills.has(skill_id):
			var skill_data: Dictionary = available_skills[skill_id].duplicate()
			skill_data["skill_id"] = skill_id
			skill_data["current_cooldown"] = skill_cooldowns.get(skill_id, 0)
			result.append(skill_data)
	return result

# 获取可用技能（已学会且不在冷却中）
func get_available_skills_for_ui(player: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in learned_skills:
		if available_skills.has(skill_id):
			var skill_data: Dictionary = available_skills[skill_id].duplicate()
			skill_data["skill_id"] = skill_id
			skill_data["current_cooldown"] = skill_cooldowns.get(skill_id, 0)
			
			# 检查是否可用
			var check = can_use_skill(skill_id, player)
			skill_data["can_use"] = check.can_use
			skill_data["reason"] = check.reason if not check.can_use else ""
			
			result.append(skill_data)
	return result

func get_skill_description(skill_id: String) -> String:
	if not available_skills.has(skill_id):
		return "未知技能"
	
	var skill: Dictionary = available_skills[skill_id]
	var desc: String = skill.get("description", "")
	var mana: int = skill.get("mana_cost", 0)
	var cooldown: int = skill.get("cooldown", 0)
	
	var info: String = desc + "\n消耗: %d MP" % mana
	if cooldown > 0:
		info += " | 冷却: %d 回合" % cooldown
	
	return info

# 存档数据
func get_save_data() -> Dictionary:
	return {
		"learned_skills": learned_skills.duplicate(),
		"skill_cooldowns": skill_cooldowns.duplicate()
	}

# 读档数据
func load_save_data(data: Dictionary) -> void:
	learned_skills.clear()
	skill_cooldowns.clear()
	
	if data.has("learned_skills"):
		# 将读取的数组转换为 String 类型
		var loaded_skills = data["learned_skills"]
		for skill_id in loaded_skills:
			if skill_id is String:
				learned_skills.append(skill_id)
	
	if data.has("skill_cooldowns"):
		skill_cooldowns = data["skill_cooldowns"].duplicate()
	
	print("技能数据已加载，已学会技能数: ", learned_skills.size())

# 检查是否已学会技能
func has_skill(skill_id: String) -> bool:
	return skill_id in learned_skills

# 添加新技能定义（用于扩展）
func add_skill_definition(skill_id: String, skill_data: Dictionary) -> void:
	available_skills[skill_id] = skill_data.duplicate()
