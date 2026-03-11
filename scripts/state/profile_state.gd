class_name ProfileState
extends RefCounted

var cycle_index: int = 1
var unlocked_endings: Array[String] = []
var global_unlocks: Dictionary = {}

func reset() -> void:
	cycle_index = 1
	unlocked_endings.clear()
	global_unlocks.clear()
