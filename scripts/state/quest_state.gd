class_name QuestState
extends RefCounted

var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var rewarded_quests: Array[String] = []

func reset() -> void:
	active_quests.clear()
	completed_quests.clear()
	rewarded_quests.clear()

func to_save_data() -> Dictionary:
	return {
		"active_quests": active_quests.duplicate(true),
		"completed_quests": completed_quests.duplicate(),
		"rewarded_quests": rewarded_quests.duplicate()
	}

func load_save_data(data: Dictionary) -> void:
	reset()

	if data.has("active_quests"):
		active_quests = data["active_quests"].duplicate(true)

	if data.has("completed_quests"):
		for quest_id in data["completed_quests"]:
			if quest_id is String:
				completed_quests.append(quest_id)

	if data.has("rewarded_quests"):
		for quest_id in data["rewarded_quests"]:
			if quest_id is String:
				rewarded_quests.append(quest_id)
