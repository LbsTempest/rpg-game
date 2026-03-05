class_name NPC
extends CharacterBody2D

signal dialogue_started(npc_name: String)
signal dialogue_ended()

@export var npc_name: String = "NPC"
@export var dialogue_lines: Array[String] = ["你好，冒险者！"]
@export var can_interact: bool = true

# 新的对话数据格式（支持分支）
# 示例：[
#   {"text": "你好！", "type": "normal"},
#   {"text": "你要去哪里？", "type": "branch", "options": [
#     {"text": "去森林", "next": 2},
#     {"text": "去村庄", "next": 3}
#   ]},
#   {"text": "森林很危险，小心！", "type": "normal"},
#   {"text": "村庄在东边，慢走！", "type": "normal"}
# ]
@export var dialogue_data: Array = []

func get_dialogue_data() -> Array:
	if dialogue_data.size() > 0:
		return dialogue_data
	# 兼容旧格式
	var data: Array = []
	for line in dialogue_lines:
		data.append({"text": line, "type": "normal"})
	return data

@export_category("移动设置")
@export var wander_radius: float = 80.0  # 游荡范围
@export var wander_speed: float = 40.0  # 游荡速度
@export var wander_interval: float = 3.0  # 改变方向间隔
@export var can_wander: bool = true  # 是否可以游荡

var current_dialogue_index: int = 0
var is_dialogue_active: bool = false

# 游荡相关
var spawn_position: Vector2
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0
var pause_timer: float = 0.0
var is_paused: bool = false

@onready var interaction_area := $InteractionArea
@onready var name_label := $NameLabel
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	spawn_position = position
	
	if name_label:
		name_label.text = npc_name
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)
	
	# 初始化游荡
	if can_wander:
		_change_wander_direction()
	
	# 加载外部对话数据（如果有 DialogeData 子节点）
	_load_external_dialogue()
	
	# 如果没有设置对话数据，使用默认分支对话（示例）
	if dialogue_data.size() == 0 and dialogue_lines.size() == 0:
		_init_default_dialogue()

func _load_external_dialogue() -> void:
	# 检查是否有 DialogueData 子节点
	var dialogue_node = get_node_or_null("DialogueData")
	if dialogue_node and dialogue_node.get("dialogue_data"):
		dialogue_data = dialogue_node.dialogue_data
		print("已加载外部对话数据: ", dialogue_data.size(), " 行")

func _init_default_dialogue() -> void:
	# 为村民NPC初始化默认分支对话
	dialogue_data = [
		{"text": "欢迎来到我们的村庄！", "type": "normal"},
		{"text": "你是来做什么的？", "type": "branch", "options": [
			{"text": "我想了解任务", "next": 2},
			{"text": "我想买东西", "next": 3},
			{"text": "随便逛逛", "next": 4}
		]},
		{"text": "最近森林里的史莱姆很活跃，请小心！", "type": "normal"},
		{"text": "商店在东边的房子里，那里有补给品。", "type": "normal"},
		{"text": "慢走，注意安全！", "type": "normal"}
	]

func _physics_process(delta: float) -> void:
	# 如果正在对话，停止移动
	if is_dialogue_active or DialogueManager.is_active:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
	
	if not can_wander:
		_play_idle_animation()
		return
	
	# 处理暂停（站在原地一段时间）
	if is_paused:
		pause_timer += delta
		if pause_timer >= 1.5:  # 停顿1.5秒
			is_paused = false
			pause_timer = 0.0
			_change_wander_direction()
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
	
	# 游荡逻辑
	wander_timer += delta
	
	# 定时改变方向或停顿
	if wander_timer >= wander_interval:
		wander_timer = 0.0
		# 30% 概率停顿
		if randf() < 0.3:
			is_paused = true
			velocity = Vector2.ZERO
			_play_idle_animation()
		else:
			_change_wander_direction()
	
	# 检查是否超出游荡范围
	if position.distance_to(spawn_position) > wander_radius:
		# 返回出生点
		wander_direction = (spawn_position - position).normalized()
	
	# 尝试移动
	var next_position = position + wander_direction * wander_speed * delta
	if _can_move_to(next_position):
		velocity = wander_direction * wander_speed
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

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_interact and not is_dialogue_active and not DialogueManager.is_active:
		# 停止移动面对玩家
		velocity = Vector2.ZERO
		_play_idle_animation()
		# 翻转朝向玩家
		if body.position.x < position.x:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
		DialogueManager.start_dialogue(self)

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

func start_dialogue() -> void:
	if dialogue_lines.is_empty():
		return
	
	is_dialogue_active = true
	current_dialogue_index = 0
	dialogue_started.emit(npc_name)
	_show_current_line()

func _show_current_line() -> void:
	if current_dialogue_index < dialogue_lines.size():
		var line := dialogue_lines[current_dialogue_index]
		print("[%s]: %s" % [npc_name, line])
	else:
		end_dialogue()

func next_line() -> void:
	current_dialogue_index += 1
	_show_current_line()

func end_dialogue() -> void:
	is_dialogue_active = false
	dialogue_ended.emit()
