extends Node

const COLLISION_SERVICE_SCRIPT = preload("res://scripts/world/collision_service.gd")
const ELEVATION_SERVICE_SCRIPT = preload("res://scripts/world/elevation_service.gd")

var _map_definitions: Dictionary = {}
var _active_map_id: String = "main_world"
var _collision_service = COLLISION_SERVICE_SCRIPT.new()
var _elevation_service = ELEVATION_SERVICE_SCRIPT.new()

func _ready() -> void:
	reload()
	if _map_definitions.has("main_world"):
		_active_map_id = "main_world"

func reload() -> void:
	_map_definitions = ContentDB.get_all_maps()

func set_active_map(map_id: String) -> void:
	if map_id.is_empty():
		return
	if not _map_definitions.has(map_id):
		push_warning("Map definition not found: " + map_id)
		return
	_active_map_id = map_id
	GameEvents.emit_domain_event("active_map_changed", {"map_id": map_id})

func get_active_map_id() -> String:
	return _active_map_id

func get_active_map_definition() -> Dictionary:
	return get_map_definition(_active_map_id)

func get_map_definition(map_id: String) -> Dictionary:
	return _map_definitions.get(map_id, {}).duplicate(true)

func can_move_segment(from_pos: Vector2, to_pos: Vector2, actor_id: String = "", tilemap_group: String = "tilemap") -> bool:
	var map_definition: Dictionary = get_active_map_definition()
	if map_definition.is_empty():
		return true

	if not _elevation_service.can_step(map_definition, from_pos, to_pos, tilemap_group):
		return false

	return _collision_service.can_traverse(map_definition, from_pos, to_pos, tilemap_group)

func get_tile_height(cell: Vector2i, map_id: String = "") -> int:
	var target_map_id: String = _active_map_id if map_id.is_empty() else map_id
	var map_definition: Dictionary = get_map_definition(target_map_id)
	if map_definition.is_empty():
		return 0
	return _elevation_service.get_height_for_cell(map_definition, cell)

func has_edge_barrier(cell: Vector2i, direction: Vector2i, map_id: String = "") -> bool:
	var target_map_id: String = _active_map_id if map_id.is_empty() else map_id
	var map_definition: Dictionary = get_map_definition(target_map_id)
	if map_definition.is_empty():
		return false
	return _collision_service.has_edge_barrier(map_definition, cell, direction)
