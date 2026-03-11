class_name PartyState
extends RefCounted

const CHARACTER_STATE_SCRIPT = preload("res://scripts/state/character_state.gd")

var active_member_ids: Array[String] = ["player"]
var reserve_member_ids: Array[String] = []
var player_state = CHARACTER_STATE_SCRIPT.new()

func reset() -> void:
	active_member_ids = ["player"]
	reserve_member_ids.clear()
	player_state = CHARACTER_STATE_SCRIPT.new()
