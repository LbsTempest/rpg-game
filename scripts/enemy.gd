class_name Enemy
extends Node2D

signal died(enemy: Enemy)
signal health_changed(current: int, maximum: int)

@export var enemy_name: String = "怪物"
@export var max_health: int = 50
@export var attack: int = 8
@export var defense: int = 2
@export var speed: int = 5
@export var experience_reward: int = 20
@export var gold_reward: int = 10

@export_category("AI设置")
@export var ai_type: int = 0  # 0: 普通, 1:  aggressive, 2:  defensive
@export var flee_threshold: float = 0.3  # 血量低于30%时逃跑

var current_health: int
var is_alive: bool = true
var is_player_turn: bool = true

@onready var sprite: ColorRect = $ColorRect
@onready var area := $Area2D

func _ready() -> void:
	current_health = max_health
	_update_sprite()
	
	# 连接碰撞信号
	if area:
		area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and is_alive:
		print("遭遇敌人: ", enemy_name)
		# 延迟一帧调用，避免碰撞时立即触发的问题
		call_deferred("_start_battle")

func _start_battle() -> void:
	BattleManager.start_battle(self)

func _update_sprite() -> void:
	if sprite:
		var health_ratio := float(current_health) / max_health
		if health_ratio > 0.6:
			sprite.color = Color(1, 0.2, 0.2)  # 红色 - 健康
		elif health_ratio > 0.3:
			sprite.color = Color(1, 0.5, 0.2)  # 橙色 - 受伤
		else:
			sprite.color = Color(0.5, 0.5, 0.5)  # 灰色 - 濒死

func take_damage(amount: int) -> void:
	var damage: int = max(1, amount - defense)
	current_health = max(0, current_health - damage)
	health_changed.emit(current_health, max_health)
	_update_sprite()
	
	if current_health <= 0:
		_die()

func _die() -> void:
	is_alive = false
	died.emit(self)

func decide_action(player: Node) -> Dictionary:
	"""AI决策返回行动类型和参数"""
	var health_ratio := float(current_health) / max_health
	
	match ai_type:
		0:  # 普通AI - 随机攻击或防御
			if randf() < 0.8:
				return {"action": "attack", "target": player}
			else:
				return {"action": "defend", "target": self}
		
		1:  # Aggressive AI - 高概率攻击
			if randf() < 0.9:
				return {"action": "attack", "target": player}
			else:
				return {"action": "defend", "target": self}
		
		2:  # Defensive AI - 低血量时防御
			if health_ratio < flee_threshold:
				return {"action": "flee", "target": self}
			elif randf() < 0.6:
				return {"action": "attack", "target": player}
			else:
				return {"action": "defend", "target": self}
	
	return {"action": "attack", "target": player}

func execute_action(action_data: Dictionary) -> Dictionary:
	"""执行行动并返回结果"""
	var action := action_data.action as String
	var target := action_data.target as Node
	var result := {"success": true, "damage": 0, "message": ""}
	
	match action:
		"attack":
			if target.has_method("take_damage"):
				target.take_damage(attack)
				result.damage = attack
				result.message = "%s 对 %s 造成 %d 点伤害！" % [enemy_name, target.name, attack]
		
		"defend":
			defense += 2  # 临时增加防御
			result.message = "%s 进入防御姿态，防御力提升！" % enemy_name
		
		"flee":
			if randf() < 0.5:
				result.success = false
				result.message = "%s 尝试逃跑..." % enemy_name
			else:
				result.message = "%s 逃跑失败！" % enemy_name
	
	return result

func get_save_data() -> Dictionary:
	return {
		"enemy_name": enemy_name,
		"max_health": max_health,
		"current_health": current_health,
		"attack": attack,
		"defense": defense,
		"experience_reward": experience_reward,
		"gold_reward": gold_reward
	}
