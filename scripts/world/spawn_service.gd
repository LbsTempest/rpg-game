extends Node

func get_active_map_id() -> String:
	return MapService.get_active_map_id()

func get_enemy_states_for_map(map_id: String = "") -> Dictionary:
	var target_map_id: String = MapService.get_active_map_id() if map_id.is_empty() else map_id
	var all_states: Dictionary = Session.run_state.world.enemy_states
	return all_states.get(target_map_id, {})

func set_enemy_states_for_map(states: Dictionary, map_id: String = "") -> void:
	var target_map_id: String = MapService.get_active_map_id() if map_id.is_empty() else map_id
	Session.run_state.world.enemy_states[target_map_id] = states.duplicate(true)
