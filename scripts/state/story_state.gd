class_name StoryState
extends RefCounted

var flags: Dictionary = {}
var current_segment_id: String = ""
var branch_choices: Dictionary = {}

func reset() -> void:
	flags.clear()
	current_segment_id = ""
	branch_choices.clear()
