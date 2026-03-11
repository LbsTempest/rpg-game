extends RefCounted

func migrate_legacy_save_data(legacy_data: Dictionary) -> Dictionary:
	return {
		"profile": {
			"version": GameConstants.SAVE_VERSION,
			"cycle_index": 1,
			"unlocked_endings": [],
			"global_unlocks": {}
		},
		"run": {
			"version": GameConstants.SAVE_VERSION,
			"timestamp": legacy_data.get("timestamp", Time.get_unix_time_from_system()),
			"current_scene": legacy_data.get("current_scene", "main"),
			"player": legacy_data.get("player", {}),
			"inventory": legacy_data.get("inventory", {}),
			"quests": legacy_data.get("quests", {}),
			"shop_inventories": legacy_data.get("shop_inventories", {}),
			"skills": legacy_data.get("skills", {}),
			"story": legacy_data.get("story", {}),
			"enemies": legacy_data.get("enemies", {})
		}
	}
