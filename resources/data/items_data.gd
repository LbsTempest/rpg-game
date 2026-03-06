extends Node

@export var items_database: Dictionary = {
	"health_potion": {
		"item_id": "health_potion",
		"item_name": "生命药水",
		"description": "恢复30点生命值",
		"icon_path": "",
		"type": "consumable",
		"equipment_slot": null,
		"price": 20,
		"sell_price": 10,
		"stackable": true,
		"max_stack": 99,
		"effects": {
			"heal_amount": 30,
			"restore_mana": 0
		}
	},
	"mana_potion": {
		"item_id": "mana_potion",
		"item_name": "魔法药水",
		"description": "恢复20点魔法值",
		"icon_path": "",
		"type": "consumable",
		"equipment_slot": null,
		"price": 15,
		"sell_price": 7,
		"stackable": true,
		"max_stack": 99,
		"effects": {
			"heal_amount": 0,
			"restore_mana": 20
		}
	},
	"iron_sword": {
		"item_id": "iron_sword",
		"item_name": "铁剑",
		"description": "一把普通的铁剑，增加5点攻击力",
		"icon_path": "res://assets/items/sword.png",
		"type": "equipment",
		"equipment_slot": "weapon",
		"price": 100,
		"sell_price": 50,
		"stackable": false,
		"max_stack": 1,
		"effects": {
			"attack": 5,
			"defense": 0
		}
	}
}
