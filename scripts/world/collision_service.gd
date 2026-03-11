class_name CollisionService
extends RefCounted

func can_traverse(map_definition: Dictionary, from_pos: Vector2, to_pos: Vector2, tilemap_group: String = "tilemap") -> bool:
	var tilemap: TileMapLayer = Engine.get_main_loop().get_first_node_in_group(tilemap_group)
	if not tilemap:
		return map_definition.get("allow_fallback_passable", true)

	var from_cell: Vector2i = tilemap.local_to_map(from_pos)
	var to_cell: Vector2i = tilemap.local_to_map(to_pos)

	if _has_edge_barrier(map_definition, from_cell, to_cell):
		return false

	var tile_data = tilemap.get_cell_tile_data(to_cell)
	if tile_data and tile_data.get_custom_data("collision"):
		return false

	return true

func has_edge_barrier(map_definition: Dictionary, cell: Vector2i, direction: Vector2i) -> bool:
	return _has_edge_barrier(map_definition, cell, cell + direction)

func _has_edge_barrier(map_definition: Dictionary, from_cell: Vector2i, to_cell: Vector2i) -> bool:
	for barrier in map_definition.get("edge_barriers", []):
		if not barrier is Dictionary:
			continue

		var ax: int = int(barrier.get("ax", 0))
		var ay: int = int(barrier.get("ay", 0))
		var bx: int = int(barrier.get("bx", 0))
		var by: int = int(barrier.get("by", 0))
		var blocked: bool = bool(barrier.get("blocked", true))
		if not blocked:
			continue

		var forward_match: bool = from_cell == Vector2i(ax, ay) and to_cell == Vector2i(bx, by)
		var reverse_match: bool = from_cell == Vector2i(bx, by) and to_cell == Vector2i(ax, ay)
		if forward_match or reverse_match:
			return true

	return false
