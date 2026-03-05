class_name Item
extends Resource

enum Type { CONSUMABLE, EQUIPMENT, KEY_ITEM }

var item_name: String = ""
var description: String = ""
var icon: Texture2D
var price: int = 0
var stackable: bool = false
var max_stack: int = 1
var item_type: Type = Type.CONSUMABLE

enum EquipmentSlot { NONE, WEAPON, ARMOR, ACCESSORY }
var equipment_slot: EquipmentSlot = EquipmentSlot.NONE

var attack: int = 0
var defense: int = 0
var heal_amount: int = 0
var restore_mana_amount: int = 0

func use(target: Node) -> bool:
	match item_type:
		Type.CONSUMABLE:
			if heal_amount > 0:
				if target.has_method("heal"):
					target.heal(heal_amount)
			if restore_mana_amount > 0:
				if target.has_method("restore_mana"):
					target.restore_mana(restore_mana_amount)
			return true
		Type.EQUIPMENT:
			return false
		Type.KEY_ITEM:
			return false
	return false
