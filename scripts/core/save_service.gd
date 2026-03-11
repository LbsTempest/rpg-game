extends Node

const SAVE_SLOT_INFO_SCRIPT = preload("res://scripts/core/save_slot_info.gd")
const PROFILE_SERIALIZER_SCRIPT = preload("res://scripts/core/profile_state_serializer.gd")
const RUN_SERIALIZER_SCRIPT = preload("res://scripts/core/run_state_serializer.gd")
const SAVE_MIGRATOR_SCRIPT = preload("res://scripts/core/save_migrator.gd")

const DEFAULT_SLOT_ID := 0
const LEGACY_SAVE_FILE_PATH := GameConstants.SAVE_FILE_PATH

func _profile_serializer():
	return PROFILE_SERIALIZER_SCRIPT.new()

func _run_serializer():
	return RUN_SERIALIZER_SCRIPT.new()

func _migrator():
	return SAVE_MIGRATOR_SCRIPT.new()

func _slot_info(slot_id: int = DEFAULT_SLOT_ID):
	return SAVE_SLOT_INFO_SCRIPT.new(slot_id)

func save_current_run(slot_id: int = DEFAULT_SLOT_ID) -> bool:
	var player = Utils.get_group_node("player")
	if player:
		Session.capture_player_state_from_node(player)

	var slot = _slot_info(slot_id)
	var profile_payload: Dictionary = _profile_serializer().serialize(Session.profile)
	var run_payload: Dictionary = _run_serializer().serialize(Session.run_state)

	return _write_json(slot.get_profile_path(), profile_payload) and _write_json(slot.get_run_path(), run_payload)

func load_current_run(slot_id: int = DEFAULT_SLOT_ID) -> bool:
	if not _ensure_migrated(slot_id):
		return false

	var slot = _slot_info(slot_id)
	var profile_payload = _read_json(slot.get_profile_path())
	var run_payload = _read_json(slot.get_run_path())

	if profile_payload.is_empty() or run_payload.is_empty():
		return false

	_profile_serializer().deserialize(profile_payload, Session.profile)
	_run_serializer().deserialize(run_payload, Session.run_state)
	_sync_runtime_state_to_scene()
	return true

func has_save_data(slot_id: int = DEFAULT_SLOT_ID) -> bool:
	var slot = _slot_info(slot_id)
	var has_slot_saves: bool = (
		FileAccess.file_exists(slot.get_profile_path())
		and FileAccess.file_exists(slot.get_run_path())
	)
	return has_slot_saves or FileAccess.file_exists(LEGACY_SAVE_FILE_PATH)

func delete_save_data(slot_id: int = DEFAULT_SLOT_ID) -> void:
	var slot = _slot_info(slot_id)
	if FileAccess.file_exists(slot.get_profile_path()):
		DirAccess.remove_absolute(slot.get_profile_path())
	if FileAccess.file_exists(slot.get_run_path()):
		DirAccess.remove_absolute(slot.get_run_path())
	if FileAccess.file_exists(LEGACY_SAVE_FILE_PATH):
		DirAccess.remove_absolute(LEGACY_SAVE_FILE_PATH)

func _ensure_migrated(slot_id: int) -> bool:
	var slot = _slot_info(slot_id)
	if FileAccess.file_exists(slot.get_profile_path()) and FileAccess.file_exists(slot.get_run_path()):
		return true

	if not FileAccess.file_exists(LEGACY_SAVE_FILE_PATH):
		return false

	var legacy_payload := _read_json(LEGACY_SAVE_FILE_PATH)
	if legacy_payload.is_empty():
		return false

	var migrated_payload := _migrator().migrate_legacy_save_data(legacy_payload)
	return (
		_write_json(slot.get_profile_path(), migrated_payload["profile"])
		and _write_json(slot.get_run_path(), migrated_payload["run"])
	)

func _sync_runtime_state_to_scene() -> void:
	var player = Utils.get_group_node("player")
	if player:
		player.load_save_data(Session.get_player_state().to_save_data())

	for enemy in get_tree().get_nodes_in_group("enemies"):
		EnemyManager.register_enemy(enemy)

func _write_json(path: String, payload: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	return true

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		return {}

	return json.data
