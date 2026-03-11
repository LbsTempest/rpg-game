extends RefCounted

@export var definitions: Dictionary = {
	"quest_first": {
		"display_name": "初出茅庐",
		"description": "村庄附近出现了史莱姆，去击败3只史莱姆保护村民。",
		"quest_type": GameConstants.QUEST_TYPE_MAIN,
		"objectives": [
			{
				"objective_type": GameConstants.OBJECTIVE_KILL,
				"target_id": "slime",
				"required": 3,
				"current": 0,
				"description": "击败史莱姆 (0/3)"
			}
		],
		"rewards": {
			"experience": 100,
			"gold": 50,
			"items": [{"item_id": "health_potion", "quantity": 3}]
		},
		"prerequisites": [],
		"offer_sources": ["villager"]
	},
	"quest_merchant": {
		"display_name": "神秘商人",
		"description": "去找神秘商人，他可能有重要的消息。",
		"quest_type": GameConstants.QUEST_TYPE_MAIN,
		"objectives": [
			{
				"objective_type": GameConstants.OBJECTIVE_TALK,
				"target_id": "merchant",
				"required": 1,
				"current": 0,
				"description": "与神秘商人对话"
			}
		],
		"rewards": {
			"experience": 50,
			"gold": 30,
			"items": [{"item_id": "iron_sword", "quantity": 1}]
		},
		"prerequisites": ["quest_first"],
		"offer_sources": ["villager"]
	}
}
