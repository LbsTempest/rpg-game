extends Node

func request_world_move(actor_id: String, current_position: Vector2, input_vector: Vector2, speed: float, delta: float) -> Dictionary:
	if input_vector == Vector2.ZERO:
		return {"moved": false, "position": current_position}

	var direction := input_vector.normalized()
	var target_position := current_position + direction * speed * delta
	if can_move_to_segment(current_position, target_position, actor_id):
		return {"moved": true, "position": target_position}
	return {"moved": false, "position": current_position}

func can_move_to_segment(from_pos: Vector2, to_pos: Vector2, actor_id: String = "") -> bool:
	return MapService.can_move_segment(from_pos, to_pos, actor_id)
