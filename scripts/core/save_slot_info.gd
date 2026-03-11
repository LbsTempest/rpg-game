class_name SaveSlotInfo
extends RefCounted

const PROFILE_PATH_PATTERN := "user://profile_slot_%d.json"
const RUN_PATH_PATTERN := "user://run_slot_%d.json"

var slot_id: int = 0

func _init(value: int = 0) -> void:
	slot_id = value

func get_profile_path() -> String:
	return PROFILE_PATH_PATTERN % slot_id

func get_run_path() -> String:
	return RUN_PATH_PATTERN % slot_id
