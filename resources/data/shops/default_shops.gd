extends RefCounted

@export var definitions: Dictionary = {
	GameConstants.SHOP_MERCHANT: {
		"display_name": "神秘商店",
		"buy_rate": GameConstants.SHOP_BUY_RATE,
		"sell_rate": GameConstants.SHOP_SELL_RATE,
		"items": [
			{"item_id": "iron_sword", "base_quantity": 1, "infinite": false},
			{"item_id": "health_potion", "base_quantity": 10, "infinite": true},
			{"item_id": "mana_potion", "base_quantity": 5, "infinite": true},
			{"item_id": "leather_armor", "base_quantity": 1, "infinite": false}
		]
	}
}
