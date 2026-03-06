# Utility Functions
# Shared utility functions used across the game
# NOTE: This is an autoload singleton, access via Utils

extends Node

func can_move_to(target_pos: Vector2, tilemap_group: String = "tilemap") -> bool:
	var tilemap: TileMapLayer = Engine.get_main_loop().get_first_node_in_group(tilemap_group)
	if not tilemap:
		return true
	
	var tile_pos: Vector2i = tilemap.local_to_map(target_pos)
	var tile_data = tilemap.get_cell_tile_data(tile_pos)
	
	if tile_data and tile_data.get_custom_data("collision"):
		return false
	
	return true

func play_animation(sprite: AnimatedSprite2D, anim_name: String) -> void:
	if not sprite or not sprite.sprite_frames:
		return
	
	if sprite.sprite_frames.has_animation(anim_name) and sprite.animation != anim_name:
		sprite.play(anim_name)

func get_group_node(group_name: String) -> Node:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		return tree.get_first_node_in_group(group_name)
	return null

func calculate_damage(base_damage: int, defense: int) -> int:
	return max(1, base_damage - defense)

func format_gold(amount: int) -> String:
	return "%d金币" % amount

func format_health(current: int, maximum: int) -> String:
	return "生命: %d/%d" % [current, maximum]

func format_mana(current: int, maximum: int) -> String:
	return "魔法: %d/%d" % [current, maximum]

func positions_equal(pos1: Vector2, pos2: Vector2, tolerance: float = 1.0) -> bool:
	return pos1.distance_to(pos2) < tolerance

func random_direction() -> Vector2:
	var angle := randf() * GameConstants.FULL_CIRCLE
	return Vector2(cos(angle), sin(angle))
