class_name ActionDefinition
extends RefCounted

static func build(action_id: String, payload: Dictionary = {}) -> Dictionary:
	return {
		"action_id": action_id,
		"payload": payload.duplicate(true)
	}
