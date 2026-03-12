class_name StoryState
extends RefCounted

var flags: Dictionary = {}
var current_segment_id: String = ""
var current_step_index: int = 0
var branch_choices: Dictionary = {}

func reset() -> void:
	flags.clear()
	current_segment_id = ""
	current_step_index = 0
	branch_choices.clear()
