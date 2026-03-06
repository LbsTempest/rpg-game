class_name NPC
extends CharacterBody2D

signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal shop_requested(shop_id: String)
signal quest_given(quest_id: String)
signal quest_completed(quest_id: String)

@export var npc_name: String = "NPC"
@export var dialogue_lines: Array[String] = ["你好，冒险者！"]
@export var can_interact: bool = true

# 任务相关
@export var gives_quest: String = ""      # 给予的任务ID
@export var completes_quest: String = ""  # 完成的任务ID
@export var is_merchant: bool = false     # 是否是商人
@export var shop_id: String = ""          # 商店ID（如果是商人）

# 新的对话数据格式（支持分支）
@export var dialogue_data: Array = []

func get_dialogue_data() -> Array:
	if dialogue_data.size() > 0:
		return _process_quest_dialogue(dialogue_data)
	# 兼容旧格式
	var data: Array = []
	for line in dialogue_lines:
		data.append({"text": line, "type": "normal"})
	return _process_quest_dialogue(data)

# 处理任务相关对话
func _process_quest_dialogue(data: Array) -> Array:
	var processed = data.duplicate(true)
	
	# 如果有可给予的任务且玩家可以接取
	if not gives_quest.is_empty() and QuestManager.can_start_quest(gives_quest):
		var quest = QuestManager.get_quest(gives_quest)
		processed.append({
			"text": "任务：%s" % quest.get("name", ""),
			"type": "branch",
			"options": [
				{"text": "接受任务", "next": -1, "action": "accept_quest"},
				{"text": "暂时不", "next": -1}
			]
		})
		processed.append({
			"text": quest.get("description", ""),
			"type": "normal"
		})
		processed.append({
			"text": "期待你的好消息！",
			"type": "normal"
		})
	
	# 如果有可完成的任务
	if not completes_quest.is_empty():
		var status = QuestManager.get_quest_status(completes_quest)
		if status == "completed":
			processed.append({
				"text": "你完成任务了！这是你的奖励。",
				"type": "branch",
				"options": [
					{"text": "领取奖励", "next": -1, "action": "reward_quest"},
					{"text": "等下再领", "next": -1}
				]
			})
	
	# 如果是商人，添加商店选项
	if is_merchant and not shop_id.is_empty():
		processed.append({
			"text": "想看看我的商品吗？",
			"type": "branch",
			"options": [
				{"text": "打开商店", "next": -1, "action": "open_shop"},
				{"text": "不用了", "next": -1}
			]
		})
	
	return processed

@export_category("移动设置")
@export var wander_radius: float = 80.0
@export var wander_speed: float = 40.0
@export var wander_interval: float = 3.0
@export var can_wander: bool = true

var current_dialogue_index: int = 0
var is_dialogue_active: bool = false

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
	
	if can_wander:
		_change_wander_direction()
	
	_load_external_dialogue()
	
	if dialogue_data.size() == 0 and dialogue_lines.size() == 0:
		_init_default_dialogue()

func _load_external_dialogue() -> void:
	var dialogue_node = get_node_or_null("DialogueData")
	if dialogue_node and dialogue_node.get("dialogue_data"):
		dialogue_data = dialogue_node.dialogue_data
		print("已加载外部对话数据: ", dialogue_data.size(), " 行")
		
		# 检查是否是商人对话
		if dialogue_node.get("SHOP_ID"):
			shop_id = dialogue_node.SHOP_ID
			is_merchant = true

func _init_default_dialogue() -> void:
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
	if is_dialogue_active or DialogueManager.is_active or GameManager.is_inventory_open:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
	
	if not can_wander:
		_play_idle_animation()
		return
	
	if is_paused:
		pause_timer += delta
		if pause_timer >= 1.5:
			is_paused = false
			pause_timer = 0.0
			_change_wander_direction()
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
	
	wander_timer += delta
	
	if wander_timer >= wander_interval:
		wander_timer = 0.0
		if randf() < 0.3:
			is_paused = true
			velocity = Vector2.ZERO
			_play_idle_animation()
		else:
			_change_wander_direction()
	
	if position.distance_to(spawn_position) > wander_radius:
		wander_direction = (spawn_position - position).normalized()
	
	var next_position = position + wander_direction * wander_speed * delta
	if _can_move_to(next_position):
		velocity = wander_direction * wander_speed
		_play_walk_animation()
		if wander_direction.x < 0:
			animated_sprite.flip_h = true
		elif wander_direction.x > 0:
			animated_sprite.flip_h = false
	else:
		velocity = Vector2.ZERO
		_change_wander_direction()
		_play_idle_animation()
	
	move_and_slide()

func _change_wander_direction() -> void:
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
		velocity = Vector2.ZERO
		_play_idle_animation()
		if body.position.x < position.x:
			animated_sprite.flip_h = true
		else:
			animated_sprite.flip_h = false
		
		# 更新任务对话（如果有talk类型的目标）
		QuestManager.update_all_quests("talk", npc_name, 1)
		
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

# 接受任务
func accept_quest() -> bool:
	if gives_quest.is_empty():
		return false
	
	if QuestManager.start_quest(gives_quest):
		quest_given.emit(gives_quest)
		return true
	return false

# 领取奖励
func reward_quest() -> bool:
	if completes_quest.is_empty():
		return false
	
	if QuestManager.reward_quest(completes_quest):
		quest_completed.emit(completes_quest)
		return true
	return false

# 打开商店
func open_shop() -> bool:
	if not is_merchant or shop_id.is_empty():
		return false
	
	if ShopManager.open_shop(shop_id):
		shop_requested.emit(shop_id)
		return true
	return false

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
