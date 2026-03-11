extends Node

signal game_saved
signal game_loaded
signal new_game_started

var current_scene_name: String:
	get:
		return Session.run_state.current_scene_name
	set(value):
		Session.run_state.current_scene_name = value

var is_paused: bool = false
var is_new_game: bool = true

var is_inventory_open: bool:
	get:
		return Session.run_state.is_inventory_open
	set(value):
		Session.run_state.is_inventory_open = value

func toggle_pause() -> void:
	is_paused = not is_paused
	get_tree().paused = is_paused

func start_new_game() -> void:
	is_new_game = true
	Session.start_new_run()
	current_scene_name = "main"
	_reset_all_managers()
	new_game_started.emit()
	change_scene(GameConstants.SCENE_MAIN)

func _reset_all_managers() -> void:
	QuestManager.reset_all_quests()
	ShopManager.reset_all()
	SkillManager.reset_skills()
	InventoryManager.reset_state()
	_give_starting_items()
	EnemyManager.reset_all_enemies()

func _give_starting_items() -> void:
	for entry in ContentDB.get_starting_item_entries():
		var item_id: String = entry.get("item_id", "")
		var quantity: int = entry.get("quantity", 1)
		if item_id.is_empty():
			continue
		var item_data := ContentDB.get_item_definition(item_id)
		if item_data.is_empty():
			push_warning("Missing starting item definition: " + item_id)
			continue
		InventoryManager.add_item(item_data, quantity)

	InventoryManager.add_gold(ContentDB.get_starting_gold())

func save_game() -> void:
	if SaveService.save_current_run():
		game_saved.emit()
		print("Game saved successfully")

func load_game() -> bool:
	is_new_game = false
	if not SaveService.load_current_run():
		return false
	game_loaded.emit()
	print("Game loaded successfully")
	return true

func apply_player_save_data(player: Node) -> void:
	Session.apply_player_state_to_node(player)

func delete_save() -> void:
	SaveService.delete_save_data()

func has_save_file() -> bool:
	return SaveService.has_save_data()

func change_scene(scene_path: String) -> void:
	current_scene_name = scene_path.get_file().get_basename()
	get_tree().change_scene_to_file(scene_path)
