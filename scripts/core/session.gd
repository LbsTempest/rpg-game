extends Node

const PROFILE_STATE_SCRIPT = preload("res://scripts/state/profile_state.gd")
const RUN_STATE_SCRIPT = preload("res://scripts/state/run_state.gd")

var profile = PROFILE_STATE_SCRIPT.new()
var run_state = RUN_STATE_SCRIPT.new()

func reset_profile() -> void:
	profile = PROFILE_STATE_SCRIPT.new()

func reset_run() -> void:
	run_state = RUN_STATE_SCRIPT.new()

func start_new_run() -> void:
	reset_run()

func get_player_state():
	return run_state.party.player_state

func capture_player_state_from_node(player: Node) -> void:
	var player_state = get_player_state()
	player_state.position = player.position
	player_state.current_map = player.current_map
	player_state.max_health = player.max_health
	player_state.max_mana = player.max_mana
	player_state.current_health = player.current_health
	player_state.current_mana = player.current_mana
	player_state.attack = player.attack
	player_state.defense = player.defense
	player_state.level = player.level
	player_state.experience = player.experience
	player_state.is_defending = player.is_defending()

func apply_player_state_to_node(player: Node) -> void:
	var player_state = get_player_state()
	player.position = player_state.position
	player.current_map = player_state.current_map
	player.max_health = player_state.max_health
	player.max_mana = player_state.max_mana
	player.current_health = player_state.current_health
	player.current_mana = player_state.current_mana
	player.attack = player_state.attack
	player.defense = player_state.defense
	player.level = player_state.level
	player.experience = player_state.experience
	player.set_defending(player_state.is_defending)

func load_player_save_data(data: Dictionary) -> void:
	get_player_state().load_save_data(data)
