extends RefCounted

@export var defaults: Dictionary = {
	"starting_gold": GameConstants.PLAYER_START_GOLD,
	"starting_items": [
		{"item_id": "health_potion", "quantity": 3},
		{"item_id": "iron_sword", "quantity": 1},
		{"item_id": "leather_armor", "quantity": 1}
	],
	"starting_skills": [
		"slash",
		"fireball"
	]
}
