extends Node

func open_shop(shop_id: String, source_id: String = "") -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if shop_id.is_empty():
		result.message = "missing_shop_id"
		return result

	result.success = ShopManager.open_shop(shop_id)
	result.message = "shop_opened" if result.success else "shop_open_failed"
	result.data = {"shop_id": shop_id, "source_id": source_id}
	if result.success:
		GameEvents.emit_domain_event("shop_opened_from_source", result.data)
	return result

func list_shop_items(shop_id: String) -> Array[Dictionary]:
	if not ShopManager.shop_definitions.has(shop_id):
		return []

	var inventory: Dictionary = ShopManager.get_shop_inventory(shop_id)

	var result: Array[Dictionary] = []
	for item_id in inventory.get("items", {}):
		var shop_item: Dictionary = inventory["items"][item_id]
		var item_data: Dictionary = shop_item.get("item_data", {}).duplicate(true)
		item_data["item_id"] = item_id
		item_data["quantity"] = shop_item.get("quantity", 0)
		item_data["infinite"] = shop_item.get("infinite", false)
		item_data["buy_price"] = int(item_data.get("price", 0) * inventory.get("buy_rate", 1.0))
		result.append(item_data)
	return result
