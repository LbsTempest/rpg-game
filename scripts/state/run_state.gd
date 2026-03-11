class_name RunState
extends RefCounted

const PARTY_STATE_SCRIPT = preload("res://scripts/state/party_state.gd")
const INVENTORY_STATE_SCRIPT = preload("res://scripts/state/inventory_state.gd")
const QUEST_STATE_SCRIPT = preload("res://scripts/state/quest_state.gd")
const SHOP_STATE_SCRIPT = preload("res://scripts/state/shop_state.gd")
const STORY_STATE_SCRIPT = preload("res://scripts/state/story_state.gd")
const WORLD_STATE_SCRIPT = preload("res://scripts/state/world_state.gd")

var current_scene_name: String = "main"
var is_inventory_open: bool = false
var party = PARTY_STATE_SCRIPT.new()
var inventory = INVENTORY_STATE_SCRIPT.new()
var quest = QUEST_STATE_SCRIPT.new()
var shop = SHOP_STATE_SCRIPT.new()
var story = STORY_STATE_SCRIPT.new()
var world = WORLD_STATE_SCRIPT.new()

func reset() -> void:
	current_scene_name = "main"
	is_inventory_open = false
	party = PARTY_STATE_SCRIPT.new()
	inventory = INVENTORY_STATE_SCRIPT.new()
	quest = QUEST_STATE_SCRIPT.new()
	shop = SHOP_STATE_SCRIPT.new()
	story = STORY_STATE_SCRIPT.new()
	world = WORLD_STATE_SCRIPT.new()
