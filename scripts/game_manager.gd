extends Node

signal game_saved
signal game_loaded
signal new_game_started

const SAVE_FILE_PATH := GameConstants.SAVE_FILE_PATH
const SAVE_VERSION := GameConstants.SAVE_VERSION

var current_scene_name: String = ""
var is_paused: bool = false
var is_new_game: bool = true
var is_inventory_open: bool = false

# Store loaded save data for application after scene change
var _loaded_save_data: Dictionary = {}

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	if event.is_action_pressed("ui_focus_next") and Input.is_action_pressed("ui_accept"):
		save_game()

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused

func start_new_game() -> void:
	is_new_game = true
	current_scene_name = "main"
	_reset_all_managers()
	new_game_started.emit()
	change_scene(GameConstants.SCENE_MAIN)

func _reset_all_managers() -> void:
	QuestManager.reset_all_quests()
	ShopManager.reset_all()
	SkillManager.reset_skills()
	InventoryManager.item_quantities.clear()
	InventoryManager.item_definitions.clear()
	InventoryManager.gold = 0
	_give_starting_items()
	EnemyManager.reset_all_enemies()

func _give_starting_items() -> void:
	var potion := {"item_id": "health_potion", "item_name": "生命药水", "item_type": GameConstants.ITEM_TYPE_CONSUMABLE, "heal_amount": 30, "price": 20, "stackable": true, "max_stack": 99}
	var sword := {"item_id": "iron_sword", "item_name": "铁剑", "item_type": GameConstants.ITEM_TYPE_EQUIPMENT, "equipment_slot": GameConstants.SLOT_WEAPON, "attack": 5, "price": 100, "stackable": false, "max_stack": 1}
	var armor := {"item_id": "leather_armor", "item_name": "皮甲", "item_type": GameConstants.ITEM_TYPE_EQUIPMENT, "equipment_slot": GameConstants.SLOT_ARMOR, "defense": 3, "price": 80, "stackable": false, "max_stack": 1}
	
	InventoryManager.add_item(potion, 3)
	InventoryManager.add_item(sword, 1)
	InventoryManager.add_item(armor, 1)
	InventoryManager.add_gold(GameConstants.PLAYER_START_GOLD)

func save_game() -> void:
	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"current_scene": current_scene_name,
		"player": _get_player_data(),
		"inventory": InventoryManager.get_save_data(),
		"quests": QuestManager.get_save_data(),
		"shop_inventories": ShopManager.get_save_data(),
		"skills": SkillManager.get_save_data(),
		"enemies": EnemyManager.get_save_data()
	}
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data, "\t"))
		file.close()
		game_saved.emit()
		print("Game saved successfully")

func _get_player_data() -> Dictionary:
	var player := Utils.get_group_node("player")
	return player.get_save_data() if player else {}

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return false
	
	var file := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return false
	
	var json_string := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	if json.parse(json_string) != OK:
		return false
	
	_loaded_save_data = json.data
	is_new_game = false
	game_loaded.emit()
	print("Game loaded successfully")
	
	# Apply manager data immediately
	_apply_manager_data(_loaded_save_data)
	
	# Store player data for application after scene change
	if _loaded_save_data.has("current_scene"):
		current_scene_name = _loaded_save_data.current_scene
	
	return true

func _apply_manager_data(data: Dictionary) -> void:
	if data.has("inventory"):
		InventoryManager.load_save_data(data["inventory"])
	if data.has("quests"):
		QuestManager.load_save_data(data["quests"])
	if data.has("shop_inventories"):
		ShopManager.load_save_data(data["shop_inventories"])
	if data.has("skills"):
		SkillManager.load_save_data(data["skills"])
	if data.has("enemies"):
		EnemyManager.load_save_data(data["enemies"])

# Called by Player when it's ready to load its data
func apply_player_save_data(player: Node) -> void:
	if _loaded_save_data.has("player"):
		player.load_save_data(_loaded_save_data["player"])
		print("Player data applied, position: (", player.position.x, ", ", player.position.y, ")")
		_loaded_save_data.erase("player")  # Clear after application

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func change_scene(scene_path: String) -> void:
	current_scene_name = scene_path.get_file().get_basename()
	get_tree().change_scene_to_file(scene_path)
