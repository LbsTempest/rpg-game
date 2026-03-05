extends Node

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
	learn_skill("slash")
	learn_skill("fireball")

func learn_skill(skill_id: String) -> bool:
	if not available_skills.has(skill_id):
		return false
	
	if skill_id in learned_skills:
		return false
	
	learned_skills.append(skill_id)
	skill_cooldowns[skill_id] = 0
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
	
	# 执行效果
	var damage: int = skill.get("damage", 0)
	var heal: int = skill.get("heal", 0)
	var skill_name: String = skill.get("name", skill_id)
	
	if damage > 0 and target and target.has_method("take_damage"):
		target.take_damage(damage)
		result.message = "使用 %s 造成 %d 点伤害！" % [skill_name, damage]
	elif heal > 0:
		player.heal(heal)
		result.message = "使用 %s 恢复 %d 点生命！" % [skill_name, heal]
	else:
		result.message = "使用 %s" % skill_name
	
	result.success = true
	return result

func reduce_cooldowns() -> void:
	"""每回合结束调用，减少所有技能冷却"""
	for skill_id in skill_cooldowns:
		if skill_cooldowns[skill_id] > 0:
			skill_cooldowns[skill_id] -= 1

func get_learned_skills() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in learned_skills:
		if available_skills.has(skill_id):
			var skill_data: Dictionary = available_skills[skill_id].duplicate()
			skill_data["skill_id"] = skill_id
			skill_data["current_cooldown"] = skill_cooldowns.get(skill_id, 0)
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
