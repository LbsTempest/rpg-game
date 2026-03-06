extends Node

@export var quest_database: Dictionary = {
	"quest_first": {
		"id": "quest_first",
		"name": "初出茅庐",
		"description": "村庄附近出现了史莱姆，去击败3只史莱姆保护村民。",
		"type": "main",
		"objectives": [
			{
				"type": "kill",
				"target": "slime",
				"required": 3,
				"current": 0,
				"description": "击败史莱姆 (0/3)"
			}
		],
		"rewards": {
			"experience": 100,
			"gold": 50,
			"items": [{"id": "health_potion", "quantity": 3}]
		},
		"prerequisites": [],
		"giver_npc": "villager"
	},
	"quest_merchant": {
		"id": "quest_merchant",
		"name": "神秘商人",
		"description": "去找神秘商人，他可能有重要的消息。",
		"type": "main",
		"objectives": [
			{
				"type": "talk",
				"target": "merchant",
				"required": 1,
				"current": 0,
				"description": "与神秘商人对话"
			}
		],
		"rewards": {
			"experience": 50,
			"gold": 30,
			"items": [{"id": "iron_sword", "quantity": 1}]
		},
		"prerequisites": ["quest_first"],
		"giver_npc": "villager"
	}
}
