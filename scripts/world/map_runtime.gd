extends Node2D

@export var map_id: String = "main_world"

func _ready() -> void:
	if not map_id.is_empty():
		MapService.set_active_map(map_id)
	GameEvents.emit_domain_event("map_runtime_ready", {"map_id": map_id})
