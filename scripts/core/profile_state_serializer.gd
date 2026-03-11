extends RefCounted

func serialize(profile) -> Dictionary:
	return {
		"version": GameConstants.SAVE_VERSION,
		"cycle_index": profile.cycle_index,
		"unlocked_endings": profile.unlocked_endings.duplicate(),
		"global_unlocks": profile.global_unlocks.duplicate(true)
	}

func deserialize(data: Dictionary, profile) -> void:
	profile.reset()
	profile.cycle_index = data.get("cycle_index", 1)

	if data.has("unlocked_endings"):
		for ending_id in data["unlocked_endings"]:
			if ending_id is String:
				profile.unlocked_endings.append(ending_id)

	if data.has("global_unlocks"):
		profile.global_unlocks = data["global_unlocks"].duplicate(true)
