class_name ElevationService
extends RefCounted

func can_step(map_definition: Dictionary, from_pos: Vector2, to_pos: Vector2, tilemap_group: String = "tilemap") -> bool:
	var tilemap: TileMapLayer = Engine.get_main_loop().get_first_node_in_group(tilemap_group)
	if not tilemap:
		return true

	var from_cell: Vector2i = tilemap.local_to_map(from_pos)
	var to_cell: Vector2i = tilemap.local_to_map(to_pos)
	var max_step: int = int(map_definition.get("max_height_step", 1))
	var from_height: int = get_height_for_cell(map_definition, from_cell)
	var to_height: int = get_height_for_cell(map_definition, to_cell)
	return abs(from_height - to_height) <= max_step

func get_height_for_cell(map_definition: Dictionary, cell: Vector2i) -> int:
	var elevation_points: Dictionary = map_definition.get("elevation_points", {})
	var key := _cell_key(cell)
	if elevation_points.has(key):
		return int(elevation_points[key])
	return int(map_definition.get("default_height", 0))

func _cell_key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]
