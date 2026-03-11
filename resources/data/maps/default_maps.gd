extends RefCounted

@export var definitions: Dictionary = {
	"main_world": {
		"display_name": "Main World",
		"scene_path": "res://scenes/world/world_root.tscn",
		"tilemap_group": "tilemap",
		"default_height": 0,
		"max_height_step": 1,
		"allow_fallback_passable": true,
		"edge_barriers": [],
		"elevation_points": {}
	}
}
