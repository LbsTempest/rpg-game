extends RefCounted

@export var definitions: Dictionary = {
	"fireball": {
		"display_name": "火球术",
		"description": "发射火球攻击敌人，造成魔法伤害",
		"mana_cost": 10,
		"base_damage": 20,
		"target_type": "enemy",
		"cooldown": 0
	},
	"heal": {
		"display_name": "治愈术",
		"description": "恢复生命值",
		"mana_cost": 15,
		"base_heal": 25,
		"target_type": "self",
		"cooldown": 2
	},
	"slash": {
		"display_name": "重斩",
		"description": "强力的物理攻击",
		"mana_cost": 5,
		"base_damage": 15,
		"target_type": "enemy",
		"cooldown": 1
	}
}
