extends Node

signal game_saved
signal game_loaded

const SAVE_FILE_PATH := "user://save_game.json"

var current_scene_name: String = ""
var is_paused: bool = false

func _ready() -> void:
	load_game()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	if event.is_action_pressed("ui_focus_next"):
		if Input.is_action_pressed("ui_accept"):
			save_game()

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused

func save_game() -> void:
	var save_data := {
		"player": get_player_save_data(),
		"inventory": InventoryManager.get_save_data(),
		"current_scene": current_scene_name,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		game_saved.emit()
		print("Game saved successfully")

func get_player_save_data() -> Dictionary:
	var player := get_tree().get_first_node_in_group("player")
	if player:
		return player.get_save_data()
	return {}

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found")
		return
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if file:
		var json_string := file.get_as_text()
		file.close()
		
		var json := JSON.new()
		var error := json.parse(json_string)
		if error == OK:
			var save_data: Dictionary = json.data
			apply_save_data(save_data)
			game_loaded.emit()
			print("Game loaded successfully")

func apply_save_data(data: Dictionary) -> void:
	if data.has("player"):
		var player := get_tree().get_first_node_in_group("player")
		if player:
			player.load_save_data(data.player)
	
	if data.has("inventory"):
		InventoryManager.load_save_data(data.inventory)
	
	if data.has("current_scene"):
		current_scene_name = data.current_scene

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func change_scene(scene_path: String) -> void:
	current_scene_name = scene_path.get_file().get_basename()
	get_tree().change_scene_to_file(scene_path)
