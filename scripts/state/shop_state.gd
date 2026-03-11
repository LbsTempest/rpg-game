class_name ShopState
extends RefCounted

var shop_inventories: Dictionary = {}

func reset() -> void:
	shop_inventories.clear()

func to_save_data() -> Dictionary:
	return {"shop_inventories": shop_inventories.duplicate(true)}

func load_save_data(data: Dictionary) -> void:
	reset()
	if data.has("shop_inventories"):
		shop_inventories = data["shop_inventories"].duplicate(true)
