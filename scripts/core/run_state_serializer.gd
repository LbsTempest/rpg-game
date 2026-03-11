extends RefCounted

func serialize(run_state) -> Dictionary:
	return {
		"version": GameConstants.SAVE_VERSION,
		"timestamp": Time.get_unix_time_from_system(),
		"current_scene": run_state.current_scene_name,
		"player": run_state.party.player_state.to_save_data(),
		"inventory": run_state.inventory.to_save_data(),
		"quests": run_state.quest.to_save_data(),
		"shop_inventories": run_state.shop.to_save_data(),
		"skills": {
			"learned_skills": run_state.party.player_state.learned_skills.duplicate(),
			"skill_cooldowns": run_state.party.player_state.skill_cooldowns.duplicate()
		},
		"story": {
			"flags": run_state.story.flags.duplicate(true),
			"current_segment_id": run_state.story.current_segment_id,
			"branch_choices": run_state.story.branch_choices.duplicate(true)
		},
		"enemies": run_state.world.to_save_data()
	}

func deserialize(data: Dictionary, run_state) -> void:
	run_state.reset()
	run_state.current_scene_name = data.get("current_scene", "main")

	if data.has("player"):
		run_state.party.player_state.load_save_data(data["player"])

	if data.has("inventory"):
		run_state.inventory.load_save_data(data["inventory"])

	if data.has("quests"):
		run_state.quest.load_save_data(data["quests"])

	if data.has("shop_inventories"):
		run_state.shop.load_save_data(data["shop_inventories"])

	if data.has("skills"):
		var skills_data: Dictionary = data["skills"]
		run_state.party.player_state.learned_skills.clear()
		run_state.party.player_state.skill_cooldowns.clear()

		if skills_data.has("learned_skills"):
			for skill_id in skills_data["learned_skills"]:
				if skill_id is String:
					run_state.party.player_state.learned_skills.append(skill_id)

		if skills_data.has("skill_cooldowns"):
			run_state.party.player_state.skill_cooldowns = skills_data["skill_cooldowns"].duplicate()

	if data.has("story"):
		var story_data: Dictionary = data["story"]
		run_state.story.flags = story_data.get("flags", {}).duplicate(true)
		run_state.story.current_segment_id = story_data.get("current_segment_id", "")
		run_state.story.branch_choices = story_data.get("branch_choices", {}).duplicate(true)

	if data.has("enemies"):
		run_state.world.load_save_data(data["enemies"])
