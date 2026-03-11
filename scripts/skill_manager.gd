extends Node

signal skill_learned(skill_id: String)
signal skill_cooldown_updated(skill_id: String, cooldown: int)

var available_skills: Dictionary = {}

var learned_skills: Array[String]:
	get:
		return _player_state().learned_skills
	set(value):
		_player_state().learned_skills = value

var skill_cooldowns: Dictionary:
	get:
		return _player_state().skill_cooldowns
	set(value):
		_player_state().skill_cooldowns = value

func _ready() -> void:
	_initialize_skills_database()
	reset_skills()

func _player_state():
	return Session.get_player_state()

func _initialize_skills_database() -> void:
	available_skills = ContentDB.get_all_skills()

func reset_skills() -> void:
	learned_skills.clear()
	skill_cooldowns.clear()

	for skill_id in ContentDB.get_starting_skill_ids():
		learn_skill(skill_id)

func learn_skill(skill_id: String) -> bool:
	if not available_skills.has(skill_id):
		return false

	if skill_id in learned_skills:
		return false

	learned_skills.append(skill_id)
	skill_cooldowns[skill_id] = 0
	skill_learned.emit(skill_id)
	return true

func can_use_skill(skill_id: String, player: Node) -> Dictionary:
	var result = {"can_use": false, "reason": ""}

	if not skill_id in learned_skills:
		result.reason = "未学会此技能"
		return result

	if not available_skills.has(skill_id):
		result.reason = "技能不存在"
		return result

	var skill = available_skills[skill_id]

	if skill_cooldowns.get(skill_id, 0) > 0:
		result.reason = "技能冷却中（还剩 %d 回合）" % skill_cooldowns[skill_id]
		return result

	var mana_cost: int = skill.get("mana_cost", 0)
	if player.current_mana < mana_cost:
		result.reason = "魔法值不足（需要 %d）" % mana_cost
		return result

	result.can_use = true
	return result

func use_skill(skill_id: String, player: Node, target = null) -> Dictionary:
	var result = {"success": false, "message": ""}

	var check = can_use_skill(skill_id, player)
	if not check.can_use:
		result.message = check.reason
		return result

	var skill = available_skills[skill_id]

	var mana_cost: int = skill.get("mana_cost", 0)
	player.use_mana(mana_cost)

	var cooldown: int = skill.get("cooldown", 0)
	if cooldown > 0:
		skill_cooldowns[skill_id] = cooldown
		skill_cooldown_updated.emit(skill_id, cooldown)

	var final_damage = _calculate_damage(skill_id, skill, player)
	var final_heal = _calculate_heal(skill_id, skill, player)
	var skill_name: String = skill.get("name", skill_id)

	if final_damage > 0 and target and target.has_method("take_damage"):
		target.take_damage(final_damage)
		result.message = "使用 %s 造成 %d 点伤害！" % [skill_name, final_damage]
	elif final_heal > 0:
		player.heal(final_heal)
		result.message = "使用 %s 恢复 %d 点生命！" % [skill_name, final_heal]
	else:
		result.message = "使用 %s" % skill_name

	result.success = true
	return result

func _calculate_damage(skill_id: String, skill: Dictionary, player: Node) -> int:
	var base_damage = skill.get("base_damage", 0)
	if base_damage <= 0:
		return 0

	match skill_id:
		"slash":
			return base_damage + int(player.attack * GameConstants.SKILL_SLASH_ATTACK_RATIO)
		"fireball":
			return base_damage + (player.level * GameConstants.SKILL_FIREBALL_LEVEL_BONUS)
		_:
			return base_damage

func _calculate_heal(skill_id: String, skill: Dictionary, player: Node) -> int:
	var base_heal = skill.get("base_heal", 0)
	if base_heal <= 0:
		return 0

	if skill_id == "heal":
		return base_heal + (player.level * GameConstants.SKILL_HEAL_LEVEL_BONUS)
	return base_heal

func reduce_cooldowns() -> void:
	for skill_id in skill_cooldowns:
		if skill_cooldowns[skill_id] > 0:
			skill_cooldowns[skill_id] -= 1
			skill_cooldown_updated.emit(skill_id, skill_cooldowns[skill_id])

func get_learned_skills() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in learned_skills:
		if available_skills.has(skill_id):
			var skill_data = available_skills[skill_id].duplicate(true)
			skill_data["skill_id"] = skill_id
			skill_data["current_cooldown"] = skill_cooldowns.get(skill_id, 0)
			result.append(skill_data)
	return result

func get_available_skills_for_ui(player: Node) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for skill_id in learned_skills:
		if available_skills.has(skill_id):
			var skill_data = available_skills[skill_id].duplicate(true)
			skill_data["skill_id"] = skill_id
			skill_data["current_cooldown"] = skill_cooldowns.get(skill_id, 0)

			var check = can_use_skill(skill_id, player)
			skill_data["can_use"] = check.can_use
			skill_data["reason"] = check.reason if not check.can_use else ""

			result.append(skill_data)
	return result

func get_skill_description(skill_id: String) -> String:
	if not available_skills.has(skill_id):
		return "未知技能"

	var skill = available_skills[skill_id]
	var desc = skill.get("description", "")
	var mana = skill.get("mana_cost", 0)
	var cooldown = skill.get("cooldown", 0)

	var info = desc + "\n消耗: %d 魔法" % mana
	if cooldown > 0:
		info += " | 冷却: %d 回合" % cooldown

	return info

func get_save_data() -> Dictionary:
	return {
		"learned_skills": learned_skills.duplicate(),
		"skill_cooldowns": skill_cooldowns.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	learned_skills.clear()
	skill_cooldowns.clear()

	if data.has("learned_skills"):
		for skill_id in data["learned_skills"]:
			if skill_id is String:
				learned_skills.append(skill_id)

	if data.has("skill_cooldowns"):
		skill_cooldowns = data["skill_cooldowns"].duplicate()

func has_skill(skill_id: String) -> bool:
	return skill_id in learned_skills

func add_skill_definition(skill_id: String, skill_data: Dictionary) -> void:
	available_skills[skill_id] = skill_data.duplicate(true)
