class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)
signal health_changed(current: int, maximum: int)

@export var enemy_name: String = "怪物"
@export var max_health: int = 50
@export var attack: int = 8
@export var defense: int = 2
@export var speed: float = 80.0
@export var experience_reward: int = 20
@export var gold_reward: int = 10

@export_category("AI设置")
@export var ai_type: int = 0  # 0: 普通, 1: aggressive, 2: defensive
@export var flee_threshold: float = 0.3  # 血量低于30%时逃跑

@export_category("移动设置")
@export var patrol_radius: float = 150.0  # 游荡范围半径
@export var detection_radius: float = 200.0  # 检测玩家范围
@export var chase_radius: float = 300.0  # 追击最大范围
@export var wander_interval: float = 2.0  # 改变游荡方向间隔

var current_health: int
var is_alive: bool = true
var is_chasing: bool = false

# 游荡相关
var spawn_position: Vector2
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

func _ready() -> void:
	current_health = max_health
	spawn_position = position
	
	# 初始化游荡方向
	_change_wander_direction()
	
	# 连接信号
	if detection_area:
		detection_area.body_entered.connect(_on_player_entered_detection)
		detection_area.body_exited.connect(_on_player_exited_detection)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	# 检查是否在战斗中
	if BattleManager.is_in_battle:
		velocity = Vector2.ZERO
		_play_idle_animation()
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		_wander(delta)
		return
	
	var distance_to_player = position.distance_to(player.position)
	
	if is_chasing and distance_to_player < chase_radius:
		# 追击玩家
		_chase_player(player, delta)
	elif distance_to_player < detection_radius:
		# 开始追击
		is_chasing = true
		_chase_player(player, delta)
	else:
		# 超出追击范围，回到游荡状态
		is_chasing = false
		_wander(delta)

func _chase_player(player: Node, delta: float) -> void:
	var direction = (player.position - position).normalized()
	
	# 检查碰撞
	var next_position = position + direction * speed * delta
	if _can_move_to(next_position):
		velocity = direction * speed * 1.5  # 追击时速度更快
		_play_walk_animation()
		# 翻转精灵
		if direction.x < 0:
			animated_sprite.flip_h = true
		elif direction.x > 0:
			animated_sprite.flip_h = false
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()
	
	move_and_slide()
	
	# 检查是否足够近触发战斗
	if position.distance_to(player.position) < 30.0:
		_start_battle()

func _wander(delta: float) -> void:
	wander_timer += delta
	
	# 定时改变游荡方向
	if wander_timer >= wander_interval:
		wander_timer = 0.0
		_change_wander_direction()
	
	# 检查是否超出游荡范围
	if position.distance_to(spawn_position) > patrol_radius:
		# 返回出生点
		wander_direction = (spawn_position - position).normalized()
	
	# 尝试移动
	var next_position = position + wander_direction * speed * delta
	if _can_move_to(next_position):
		velocity = wander_direction * speed
		_play_walk_animation()
		# 翻转精灵
		if wander_direction.x < 0:
			animated_sprite.flip_h = true
		elif wander_direction.x > 0:
			animated_sprite.flip_h = false
	else:
		# 碰到障碍，改变方向
		velocity = Vector2.ZERO
		_change_wander_direction()
		_play_idle_animation()
	
	move_and_slide()

func _change_wander_direction() -> void:
	# 随机选择一个新的游荡方向
	var angle = randf() * 2 * PI
	wander_direction = Vector2(cos(angle), sin(angle))

func _can_move_to(target_pos: Vector2) -> bool:
	var tilemap: TileMapLayer = get_tree().get_first_node_in_group("tilemap")
	if not tilemap:
		return true
	
	var tile_pos: Vector2i = tilemap.local_to_map(target_pos)
	var tile_data = tilemap.get_cell_tile_data(tile_pos)
	
	if tile_data and tile_data.get_custom_data("collision"):
		return false
	
	return true

func _on_player_entered_detection(body: Node2D) -> void:
	if body.is_in_group("player") and is_alive and not BattleManager.is_in_battle:
		is_chasing = true

func _on_player_exited_detection(body: Node2D) -> void:
	if body.is_in_group("player"):
		# 玩家离开检测区域，但还会继续追击直到超出追击范围
		pass

func _start_battle() -> void:
	if is_alive and not BattleManager.is_in_battle:
		velocity = Vector2.ZERO
		BattleManager.start_battle(self)

func take_damage(amount: int) -> void:
	var damage: int = max(1, amount - defense)
	current_health = max(0, current_health - damage)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_die()

func _die() -> void:
	is_alive = false
	velocity = Vector2.ZERO
	# 播放死亡动画（如果有）
	if animated_sprite and animated_sprite.sprite_frames and animated_sprite.sprite_frames.has_animation("death"):
		animated_sprite.play("death")
	else:
		# 如果没有死亡动画，隐藏色块
		var color_rect = get_node_or_null("ColorRect")
		if color_rect:
			color_rect.visible = false
	died.emit(self)

func _play_walk_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("walk"):
			if animated_sprite.animation != "walk":
				animated_sprite.play("walk")

func _play_idle_animation() -> void:
	if animated_sprite and animated_sprite.sprite_frames:
		if animated_sprite.sprite_frames.has_animation("idle"):
			if animated_sprite.animation != "idle":
				animated_sprite.play("idle")

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
		"gold_reward": gold_reward,
		"position": {"x": position.x, "y": position.y},
		"spawn_position": {"x": spawn_position.x, "y": spawn_position.y}
	}
