class_name WorldState
extends RefCounted

var enemy_states: Dictionary = {}

func reset() -> void:
	enemy_states.clear()

func to_save_data() -> Dictionary:
	return enemy_states.duplicate(true)

func load_save_data(data: Dictionary) -> void:
	reset()
	if data.size() > 0:
		enemy_states = data.duplicate(true)
