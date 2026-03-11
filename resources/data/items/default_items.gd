extends RefCounted

@export var definitions: Dictionary = {
	"health_potion": {
		"display_name": "生命药水",
		"description": "恢复30点生命值",
		"icon_path": "",
		"item_type": GameConstants.ITEM_TYPE_CONSUMABLE,
		"price": 20,
		"sell_price": 10,
		"stackable": true,
		"max_stack": 99,
		"heal_amount": 30
	},
	"mana_potion": {
		"display_name": "魔法药水",
		"description": "恢复20点魔法值",
		"icon_path": "",
		"item_type": GameConstants.ITEM_TYPE_CONSUMABLE,
		"price": 15,
		"sell_price": 7,
		"stackable": true,
		"max_stack": 99,
		"restore_mana_amount": 20
	},
	"iron_sword": {
		"display_name": "铁剑",
		"description": "一把普通的铁剑，增加5点攻击力",
		"icon_path": "res://assets/items/sword.png",
		"item_type": GameConstants.ITEM_TYPE_EQUIPMENT,
		"equipment_slot": GameConstants.SLOT_WEAPON,
		"price": 100,
		"sell_price": 50,
		"stackable": false,
		"max_stack": 1,
		"attack": 5
	},
	"leather_armor": {
		"display_name": "皮甲",
		"description": "基础的皮制护甲",
		"icon_path": "",
		"item_type": GameConstants.ITEM_TYPE_EQUIPMENT,
		"equipment_slot": GameConstants.SLOT_ARMOR,
		"price": 80,
		"sell_price": 40,
		"stackable": false,
		"max_stack": 1,
		"defense": 3
	}
}
