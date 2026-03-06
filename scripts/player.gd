class_name Player
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal level_up(new_level: int)
signal died()

@export var move_speed: float = 200.0
@export var current_map: String = "world"

@export_category("Stats")
@export var max_health: int = 100
@export var max_mana: int = 50
@export var attack: int = 10
@export var defense: int = 5
@export var level: int = 1
@export var experience: int = 0

var current_health: int
var current_mana: int
var experience_to_next_level: int

var _direction: Vector2 = Vector2.ZERO
var _facing_direction: Vector2 = Vector2.DOWN
var _is_defending: bool = false

@onready var animated_sprite := $AnimatedSprite2D

enum Direction { UP, DOWN, LEFT, RIGHT }

func _ready() -> void:
	current_health = max_health
	current_mana = max_mana
	experience_to_next_level = _calculate_exp_requirement()
	_update_ui()

func _physics_process(delta: float) -> void:
	# 如果对话、战斗或物品栏正在进行，停止移动
	if DialogueManager.is_active or BattleManager.is_in_battle or GameManager.is_inventory_open:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		return
	
	# 获取输入方向
	_direction = Vector2.ZERO
	_direction.x = Input.get_axis("move_left", "move_right")
	_direction.y = Input.get_axis("move_up", "move_down")
	
	if _direction != Vector2.ZERO:
		_direction = _direction.normalized()
		_facing_direction = _direction
		
		# 检查前方是否可以移动
		var next_position = position + _direction * move_speed * delta
		if _can_move_to(next_position):
			velocity = _direction * move_speed
			_play_walk_animation()
		else:
			# 碰到障碍，停止
			velocity = Vector2.ZERO
			_play_idle_animation()
	else:
		# 没有输入，立即停止
		velocity = Vector2.ZERO
		_play_idle_animation()
	
	# 应用移动
	move_and_slide()
	_update_facing()

func _can_move_to(target_pos: Vector2) -> bool:
	var tilemap: TileMapLayer = get_tree().get_first_node_in_group("tilemap")
	if not tilemap:
		return true
	
	var tile_pos: Vector2i = tilemap.local_to_map(target_pos)
	var tile_data = tilemap.get_cell_tile_data(tile_pos)
	
	if tile_data and tile_data.get_custom_data("collision"):
		return false
	
	return true

func _play_walk_animation() -> void:
	if animated_sprite.animation != "walk":
		animated_sprite.play("walk")

func _play_idle_animation() -> void:
	if animated_sprite.animation != "idle":
		animated_sprite.play("idle")

func _update_facing() -> void:
	# 根据朝向翻转精灵
	if _facing_direction.x < 0:
		animated_sprite.flip_h = true
	elif _facing_direction.x > 0:
		animated_sprite.flip_h = false

func _get_direction_animation(prefix: String) -> String:
	var dir: String = ""
	if _facing_direction.y < 0:
		dir = "up"
	elif _facing_direction.y > 0:
		dir = "down"
	elif _facing_direction.x < 0:
		dir = "left"
	elif _facing_direction.x > 0:
		dir = "right"
	return "%s_%s" % [prefix, dir]

func get_total_attack() -> int:
	return attack + InventoryManager.get_total_attack()

func get_total_defense() -> int:
	return defense + InventoryManager.get_total_defense()

func take_damage(amount: int) -> void:
	var total_defense = get_total_defense()
	# 防御姿态时防御力翻倍
	if _is_defending:
		total_defense *= 2
	
	var damage_val: int = max(1, amount - total_defense)
	current_health = max(0, current_health - damage_val)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		died.emit()

func set_defending(defending: bool) -> void:
	_is_defending = defending

func is_defending() -> bool:
	return _is_defending

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)

func restore_mana(amount: int) -> void:
	current_mana = min(max_mana, current_mana + amount)
	mana_changed.emit(current_mana, max_mana)

func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, max_mana)
		return true
	return false

func add_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		level_up_character()

func _calculate_exp_requirement() -> int:
	return level * 100

func level_up_character() -> void:
	level += 1
	max_health += 10
	max_mana += 5
	attack += 2
	defense += 1
	current_health = max_health
	current_mana = max_mana
	experience_to_next_level = _calculate_exp_requirement()
	level_up.emit(level)
	_update_ui()

func _update_ui() -> void:
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)

func get_save_data() -> Dictionary:
	return {
		"position": {"x": position.x, "y": position.y},
		"current_map": current_map,
		"max_health": max_health,
		"max_mana": max_mana,
		"current_health": current_health,
		"current_mana": current_mana,
		"attack": attack,
		"defense": defense,
		"level": level,
		"experience": experience
	}

func load_save_data(data: Dictionary) -> void:
	if data.has("position"):
		var old_pos = position
		position = Vector2(data.position.x, data.position.y)
		print("Player: 位置从 (", old_pos.x, ", ", old_pos.y, ") 加载为 (", position.x, ", ", position.y, ")")
	if data.has("current_map"):
		current_map = data.current_map
	if data.has("max_health"):
		max_health = data.max_health
	if data.has("max_mana"):
		max_mana = data.max_mana
	if data.has("current_health"):
		current_health = data.current_health
	if data.has("current_mana"):
		current_mana = data.current_mana
	if data.has("attack"):
		attack = data.attack
	if data.has("defense"):
		defense = data.defense
	if data.has("level"):
		level = data.level
	if data.has("experience"):
		experience = data.experience
	
	experience_to_next_level = _calculate_exp_requirement()
	_update_ui()
