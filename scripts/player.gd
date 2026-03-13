class_name Player
extends CharacterBody2D

signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal level_up(new_level: int)
signal died()

@export var move_speed: float = GameConstants.PLAYER_SPEED
@export var current_map: String = "world"

@export_category("Stats")
@export var max_health: int = GameConstants.PLAYER_START_HEALTH
@export var max_mana: int = GameConstants.PLAYER_START_MANA
@export var attack: int = GameConstants.PLAYER_START_ATTACK
@export var defense: int = GameConstants.PLAYER_START_DEFENSE
@export var level: int = GameConstants.PLAYER_START_LEVEL
@export var experience: int = 0

var current_health: int
var current_mana: int
var experience_to_next_level: int

var _direction: Vector2 = Vector2.ZERO
var _facing_direction: Vector2 = Vector2.DOWN
var _is_defending: bool = false

@onready var animated_sprite := $AnimatedSprite2D

func _ready() -> void:
	if App.is_new_game:
		current_health = max_health
		current_mana = max_mana
		experience_to_next_level = _calculate_exp_requirement()
		_sync_state_to_session()
	else:
		App.apply_player_save_data(self)
		experience_to_next_level = _calculate_exp_requirement()

	_update_ui()

func _physics_process(delta: float) -> void:
	if DialogueService.is_active or BattleService.is_in_battle or App.is_inventory_open:
		velocity = Vector2.ZERO
		_play_idle_animation()
		move_and_slide()
		_sync_state_to_session()
		return

	_direction = Vector2.ZERO
	_direction.x = Input.get_axis("move_left", "move_right")
	_direction.y = Input.get_axis("move_up", "move_down")

	if _direction != Vector2.ZERO:
		_direction = _direction.normalized()
		_facing_direction = _direction

		var next_position = position + _direction * move_speed * delta
		if MovementService.can_move_to_segment(position, next_position, "player"):
			velocity = _direction * move_speed
			_play_walk_animation()
		else:
			velocity = Vector2.ZERO
			_play_idle_animation()
	else:
		velocity = Vector2.ZERO
		_play_idle_animation()

	move_and_slide()
	_update_facing()
	_sync_state_to_session()

func _play_walk_animation() -> void:
	Utils.play_animation(animated_sprite, "walk")

func _play_idle_animation() -> void:
	Utils.play_animation(animated_sprite, "idle")

func _update_facing() -> void:
	if _facing_direction.x < 0:
		animated_sprite.flip_h = true
	elif _facing_direction.x > 0:
		animated_sprite.flip_h = false

func _sync_state_to_session() -> void:
	Session.capture_player_state_from_node(self)

func _apply_state_from_session() -> void:
	Session.apply_player_state_to_node(self)

func get_total_attack() -> int:
	return attack + InventoryService.get_total_attack()

func get_total_defense() -> int:
	return defense + InventoryService.get_total_defense()

func take_damage(amount: int) -> void:
	var total_defense = get_total_defense()
	if _is_defending:
		total_defense = int(total_defense * GameConstants.DEFEND_DEFENSE_MULTIPLIER)

	var damage_val: int = Utils.calculate_damage(amount, total_defense)
	current_health = max(0, current_health - damage_val)
	_sync_state_to_session()
	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		died.emit()

func heal(amount: int) -> void:
	current_health = min(max_health, current_health + amount)
	_sync_state_to_session()
	health_changed.emit(current_health, max_health)

func restore_mana(amount: int) -> void:
	current_mana = min(max_mana, current_mana + amount)
	_sync_state_to_session()
	mana_changed.emit(current_mana, max_mana)

func use_mana(amount: int) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		_sync_state_to_session()
		mana_changed.emit(current_mana, max_mana)
		return true
	return false

func set_defending(defending: bool) -> void:
	_is_defending = defending
	_sync_state_to_session()

func is_defending() -> bool:
	return _is_defending

func add_experience(amount: int) -> void:
	experience += amount
	while experience >= experience_to_next_level:
		experience -= experience_to_next_level
		_level_up()
	_sync_state_to_session()

func _calculate_exp_requirement() -> int:
	return level * GameConstants.EXP_PER_LEVEL

func _level_up() -> void:
	level += 1
	max_health += GameConstants.LEVELUP_HEALTH_BONUS
	max_mana += GameConstants.LEVELUP_MANA_BONUS
	attack += GameConstants.LEVELUP_ATTACK_BONUS
	defense += GameConstants.LEVELUP_DEFENSE_BONUS
	current_health = max_health
	current_mana = max_mana
	experience_to_next_level = _calculate_exp_requirement()
	_sync_state_to_session()
	level_up.emit(level)
	_update_ui()

func _update_ui() -> void:
	health_changed.emit(current_health, max_health)
	mana_changed.emit(current_mana, max_mana)

func get_save_data() -> Dictionary:
	_sync_state_to_session()
	return Session.get_player_state().to_save_data()

func load_save_data(data: Dictionary) -> void:
	Session.load_player_save_data(data)
	_apply_state_from_session()
	experience_to_next_level = _calculate_exp_requirement()
	_update_ui()
