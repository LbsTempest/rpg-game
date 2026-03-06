class_name NPC
extends CharacterBody2D

signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal shop_requested(shop_id: String)
signal quest_given(quest_id: String)
signal quest_completed(quest_id: String)

@export var npc_name: String = GameConstants.DEFAULT_NPC_NAME
@export var dialogue_lines: Array[String] = []
@export var can_interact: bool = true

@export var gives_quest: String = ""
@export var completes_quest: String = ""
@export var is_merchant: bool = false
@export var shop_id: String = ""

@export var dialogue_data: Array = []

@export_category("Movement")
@export var wander_radius: float = GameConstants.NPC_WANDER_RADIUS
@export var wander_speed: float = GameConstants.NPC_WANDER_SPEED
@export var wander_interval: float = GameConstants.NPC_WANDER_INTERVAL
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
	
	interaction_area.body_entered.connect(_on_player_entered)
	
	if can_wander:
		wander_direction = Utils.random_direction()
	
	_load_external_dialogue()
	
	if dialogue_data.size() == 0 and dialogue_lines.size() == 0:
		_init_default_dialogue()

func _load_external_dialogue() -> void:
	var dialogue_node = get_node_or_null("DialogueData")
	if dialogue_node and dialogue_node.get("dialogue_data"):
		dialogue_data = dialogue_node.dialogue_data
		
		if dialogue_node.get("SHOP_ID"):
			shop_id = dialogue_node.SHOP_ID
			is_merchant = true

func _init_default_dialogue() -> void:
	var dialogue_resource = load("res://resources/dialogues/default_npc_dialogue.gd").new()
	dialogue_data = dialogue_resource.dialogue_data.duplicate(true)
	dialogue_resource.free()

func get_dialogue_data() -> Array:
	if dialogue_data.size() > 0:
		return _process_quest_dialogue(dialogue_data)
	
	var data: Array = []
	for line in dialogue_lines:
		data.append({"text": line, "type": "normal"})
	return _process_quest_dialogue(data)

func _process_quest_dialogue(data: Array) -> Array:
	var processed = data.duplicate(true)
	
	if not gives_quest.is_empty() and QuestManager.can_start_quest(gives_quest):
		var quest = QuestManager.get_quest(gives_quest)
		processed.append({
			"text": "任务：%s" % quest.get("name", ""),
			"type": "branch",
			"options": [
				{"text": "接受", "next": -1, "action": "accept_quest"},
				{"text": "暂不接受", "next": -1}
			]
		})
		processed.append({"text": quest.get("description", ""), "type": "normal"})
		processed.append({"text": "祝你好运！", "type": "normal"})
	
	if not completes_quest.is_empty():
		var status = QuestManager.get_quest_status(completes_quest)
		if status == "completed":
			processed.append({
				"text": "你完成了任务！这是你的奖励。",
				"type": "branch",
				"options": [
					{"text": "领取奖励", "next": -1, "action": "reward_quest"},
					{"text": "稍后再领", "next": -1}
				]
			})
	
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

func _physics_process(delta: float) -> void:
	if is_dialogue_active or DialogueManager.is_active or GameManager.is_inventory_open:
		velocity = Vector2.ZERO
		Utils.play_animation(animated_sprite, "idle")
		move_and_slide()
		return
	
	if not can_wander:
		Utils.play_animation(animated_sprite, "idle")
		return
	
	if is_paused:
		pause_timer += delta
		if pause_timer >= GameConstants.NPC_PAUSE_TIME:
			is_paused = false
			pause_timer = 0.0
			wander_direction = Utils.random_direction()
		velocity = Vector2.ZERO
		Utils.play_animation(animated_sprite, "idle")
		move_and_slide()
		return
	
	wander_timer += delta
	
	if wander_timer >= wander_interval:
		wander_timer = 0.0
		if randf() < GameConstants.NPC_PAUSE_CHANCE:
			is_paused = true
			velocity = Vector2.ZERO
			Utils.play_animation(animated_sprite, "idle")
		else:
			wander_direction = Utils.random_direction()
	
	if position.distance_to(spawn_position) > wander_radius:
		wander_direction = (spawn_position - position).normalized()
	
	var next_position = position + wander_direction * wander_speed * delta
	if Utils.can_move_to(next_position):
		velocity = wander_direction * wander_speed
		Utils.play_animation(animated_sprite, "walk")
		animated_sprite.flip_h = wander_direction.x < 0
	else:
		velocity = Vector2.ZERO
		wander_direction = Utils.random_direction()
		Utils.play_animation(animated_sprite, "idle")
	
	move_and_slide()

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_interact and not is_dialogue_active and not DialogueManager.is_active:
		velocity = Vector2.ZERO
		Utils.play_animation(animated_sprite, "idle")
		animated_sprite.flip_h = body.position.x < position.x
		
		QuestManager.update_all_quests(GameConstants.OBJECTIVE_TALK, npc_name, 1)
		
		DialogueManager.start_dialogue(self)

func accept_quest() -> bool:
	if gives_quest.is_empty():
		return false
	
	if QuestManager.start_quest(gives_quest):
		quest_given.emit(gives_quest)
		return true
	return false

func reward_quest() -> bool:
	if completes_quest.is_empty():
		return false
	
	if QuestManager.reward_quest(completes_quest):
		quest_completed.emit(completes_quest)
		return true
	return false

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
		print("[%s]: %s" % [npc_name, dialogue_lines[current_dialogue_index]])
	else:
		end_dialogue()

func next_line() -> void:
	current_dialogue_index += 1
	_show_current_line()

func end_dialogue() -> void:
	is_dialogue_active = false
	dialogue_ended.emit()
