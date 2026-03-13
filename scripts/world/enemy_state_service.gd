extends Node

var enemy_states: Dictionary:
	get:
		return _world_state().enemy_states
	set(value):
		_world_state().enemy_states = value

func _ready() -> void:
	print("EnemyStateService 初始化完成")

func _world_state():
	return Session.run_state.world

func register_enemy(enemy: Node) -> void:
	var map_id := _get_active_map_id()
	var enemy_id = _get_enemy_id(enemy)
	var map_states := _get_map_enemy_states(map_id)

	if map_states.has(enemy_id):
		_load_enemy_state(enemy, map_states[enemy_id])
	else:
		_save_enemy_state(enemy)

func _save_enemy_state(enemy: Node) -> void:
	if not enemy.has_method("get_save_data"):
		return

	var map_id := _get_active_map_id()
	var enemy_id = _get_enemy_id(enemy)
	var state = enemy.get_save_data()
	var is_alive = enemy.is_alive if "is_alive" in enemy else true
	state["is_alive"] = is_alive
	_ensure_map_bucket(map_id)
	enemy_states[map_id][enemy_id] = state

func _load_enemy_state(enemy: Node, state: Dictionary) -> void:
	if not enemy.has_method("load_save_data"):
		return

	enemy.load_save_data(state)

	if state.has("is_alive"):
		var is_alive = state.is_alive
		enemy.is_alive = is_alive
		if not is_alive:
			enemy.visible = false
			enemy.process_mode = Node.PROCESS_MODE_DISABLED

func update_enemy_state(enemy: Node) -> void:
	_save_enemy_state(enemy)

func _get_enemy_id(enemy: Node) -> String:
	var enemy_name = enemy.enemy_name if "enemy_name" in enemy else "Enemy"
	var spawn_pos = enemy.spawn_position if "spawn_position" in enemy else Vector2.ZERO
	return "%s_%.0f_%.0f" % [enemy_name, spawn_pos.x, spawn_pos.y]

func get_save_data() -> Dictionary:
	var map_id := _get_active_map_id()
	var all_enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in all_enemies:
		if enemy.has_method("get_save_data"):
			_save_enemy_state(enemy)
	if enemy_states.has(map_id):
		enemy_states[map_id] = _get_map_enemy_states(map_id)

	return _world_state().to_save_data()

func load_save_data(data: Dictionary) -> void:
	_world_state().load_save_data(data)
	_migrate_flat_enemy_state_if_needed()

func reset_all_enemies() -> void:
	_world_state().reset()

func _get_active_map_id() -> String:
	var map_id: String = MapService.get_active_map_id()
	if map_id.is_empty():
		return "main_world"
	return map_id

func _ensure_map_bucket(map_id: String) -> void:
	if not enemy_states.has(map_id):
		enemy_states[map_id] = {}

func _get_map_enemy_states(map_id: String) -> Dictionary:
	_ensure_map_bucket(map_id)
	return enemy_states[map_id]

func _migrate_flat_enemy_state_if_needed() -> void:
	if enemy_states.is_empty():
		return

	var has_flat_entries: bool = false
	for key in enemy_states:
		var value = enemy_states[key]
		if value is Dictionary and value.has("is_alive"):
			has_flat_entries = true
			break

	if not has_flat_entries:
		return

	var migrated: Dictionary = {}
	var target_map_id := _get_active_map_id()
	migrated[target_map_id] = {}
	for enemy_id in enemy_states:
		var state = enemy_states[enemy_id]
		if state is Dictionary and state.has("is_alive"):
			migrated[target_map_id][enemy_id] = state
	enemy_states = migrated
