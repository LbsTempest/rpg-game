extends Node

@export var skills_database: Dictionary = {
	"fireball": {
		"name": "火球术",
		"description": "发射火球攻击敌人，造成魔法伤害",
		"mana_cost": 10,
		"base_damage": 20,
		"heal": 0,
		"target": "enemy",
		"cooldown": 0
	},
	"heal": {
		"name": "治愈术",
		"description": "恢复生命值",
		"mana_cost": 15,
		"base_damage": 0,
		"base_heal": 25,
		"target": "self",
		"cooldown": 2
	},
	"slash": {
		"name": "重斩",
		"description": "强力的物理攻击",
		"mana_cost": 5,
		"base_damage": 15,
		"heal": 0,
		"target": "enemy",
		"cooldown": 1
	}
}
