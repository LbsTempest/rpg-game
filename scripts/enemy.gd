class_name Enemy
extends CharacterBody2D

signal died(enemy: Enemy)
signal health_changed(current: int, maximum: int)

@export var enemy_name: String = GameConstants.DEFAULT_ENEMY_NAME
@export var max_health: int = 50
@export var attack: int = GameConstants.PLAYER_START_ATTACK - 2
@export var defense: int = GameConstants.PLAYER_START_DEFENSE - 3
@export var speed: float = GameConstants.ENEMY_WANDER_SPEED
@export var experience_reward: int = 20
@export var gold_reward: int = 10

@export_category("AI Settings")
@export var ai_type: int = 0
@export var flee_threshold: float = GameConstants.AI_FLEE_THRESHOLD

@export_category("Movement")
@export var patrol_radius: float = GameConstants.ENEMY_PATROL_RADIUS
@export var detection_radius: float = GameConstants.ENEMY_DETECTION_RADIUS
@export var chase_radius: float = GameConstants.ENEMY_CHASE_RADIUS
@export var wander_interval: float = GameConstants.ENEMY_WANDER_INTERVAL

var current_health: int
var is_alive: bool = true
var is_chasing: bool = false
var _defense_boost: int = 0

var spawn_position: Vector2
var wander_direction: Vector2 = Vector2.ZERO
var wander_timer: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var detection_area: Area2D = $DetectionArea

func _ready() -> void:
	current_health = max_health
	spawn_position = position
	add_to_group("enemies")
	wander_direction = Utils.random_direction()
	
	detection_area.body_entered.connect(_on_player_entered_detection)
	detection_area.body_exited.connect(_on_player_exited_detection)
	
	call_deferred("_register_to_manager")

func _register_to_manager() -> void:
	EnemyManager.register_enemy(self)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	
	if BattleManager.is_in_battle or DialogueManager.is_active or GameManager.is_inventory_open:
		velocity = Vector2.ZERO
		Utils.play_animation(animated_sprite, "idle")
		return
	
	var player := Utils.get_group_node("player")
	if not player:
		_wander(delta)
		return
	
	var distance := position.distance_to(player.position)
	
	if is_chasing and distance < chase_radius:
		_chase_player(player, delta)
	elif distance < detection_radius:
		is_chasing = true
		_chase_player(player, delta)
	else:
		is_chasing = false
		_wander(delta)

func _chase_player(player: Node, delta: float) -> void:
	var direction: Vector2 = (player.position - position).normalized()
	var next_position: Vector2 = position + direction * speed * delta
	
	if MovementService.can_move_to_segment(position, next_position, "enemy"):
		velocity = direction * speed * 1.5
		Utils.play_animation(animated_sprite, "walk")
		animated_sprite.flip_h = direction.x < 0
	else:
		velocity = Vector2.ZERO
		Utils.play_animation(animated_sprite, "idle")
	
	move_and_slide()
	
	if position.distance_to(player.position) < GameConstants.BATTLE_TRIGGER_DISTANCE:
		_start_battle()

func _wander(delta: float) -> void:
	wander_timer += delta
	
	if wander_timer >= wander_interval:
		wander_timer = 0.0
		wander_direction = Utils.random_direction()
	
	if position.distance_to(spawn_position) > patrol_radius:
		wander_direction = (spawn_position - position).normalized()
	
	var next_position := position + wander_direction * speed * delta
	if MovementService.can_move_to_segment(position, next_position, "enemy"):
		velocity = wander_direction * speed
		Utils.play_animation(animated_sprite, "walk")
		animated_sprite.flip_h = wander_direction.x < 0
	else:
		velocity = Vector2.ZERO
		wander_direction = Utils.random_direction()
		Utils.play_animation(animated_sprite, "idle")
	
	move_and_slide()

func take_damage(amount: int) -> void:
	var damage := Utils.calculate_damage(amount, get_total_defense())
	current_health = max(0, current_health - damage)
	health_changed.emit(current_health, max_health)
	
	if current_health <= 0:
		_die()

func get_total_defense() -> int:
	return defense + _defense_boost

func reset_defense_boost() -> void:
	_defense_boost = 0

func _die() -> void:
	is_alive = false
	velocity = Vector2.ZERO
	EnemyManager.update_enemy_state(self)
	Utils.play_animation(animated_sprite, "death")
	died.emit(self)

func _start_battle() -> void:
	if is_alive and not BattleManager.is_in_battle:
		velocity = Vector2.ZERO
		BattleManager.start_battle(self)

func decide_action(player: Node) -> Dictionary:
	if not is_alive:
		return {"action": "flee", "target": player}
	
	var health_ratio := float(current_health) / float(max_health)
	
	match ai_type:
		1: # Aggressive
			return {"action": "attack", "target": player}
		2: # Defensive
			if health_ratio < flee_threshold:
				return {"action": "flee", "target": player}
			_defense_boost = GameConstants.DEFEND_TEMP_BONUS
			return {"action": "defend", "target": self}
		_:
			# Normal
			if randf() < GameConstants.AI_ATTACK_CHANCE_NORMAL:
				return {"action": "attack", "target": player}
			_defense_boost = GameConstants.DEFEND_TEMP_BONUS
			return {"action": "defend", "target": self}

func execute_action(action_data: Dictionary) -> Dictionary:
	var action: String = action_data.action
	var target: Node = action_data.target
	var result := {"success": true, "damage": 0, "message": ""}
	
	match action:
		"attack":
			target.take_damage(attack)
			result.damage = attack
			result.message = "%s dealt %d damage!" % [enemy_name, attack]
		"defend":
			result.message = "%s is defending!" % enemy_name
		"flee":
			result.message = "%s attempted to flee!" % enemy_name
	
	return result

func load_save_data(data: Dictionary) -> void:
	if data.has("current_health"):
		current_health = data.current_health
	if data.has("position"):
		position = Vector2(data.position.x, data.position.y)
	if data.has("is_alive"):
		is_alive = data.is_alive
		if not is_alive:
			visible = false
			process_mode = Node.PROCESS_MODE_DISABLED

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
		"spawn_position": {"x": spawn_position.x, "y": spawn_position.y},
		"is_alive": is_alive
	}

func _on_player_entered_detection(body: Node2D) -> void:
	if body.is_in_group("player") and is_alive:
		is_chasing = true

func _on_player_exited_detection(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_chasing = false
