extends Node

signal shop_opened(shop_id: String)
signal shop_closed
signal item_purchased(item_id: String, quantity: int, price: int)
signal item_sold(item_id: String, quantity: int, price: int)

var _shop_definitions: Dictionary = {}
var _current_shop_id: String = ""
var _current_shop_data: Dictionary = {}
var _ui_controller: ShopScreen = null

func _ready() -> void:
	_reload_definitions()

func _state():
	return Session.run_state.shop

func _reload_definitions() -> void:
	_shop_definitions = ContentDB.get_all_shops()

func reset_state() -> void:
	_state().reset()
	_current_shop_id = ""
	_current_shop_data.clear()
	if _ui_controller:
		_ui_controller.queue_free()
		_ui_controller = null

func open_shop(shop_id: String, source_id: String = "") -> Dictionary:
	var result := {"success": false, "message": "", "data": {}}
	if shop_id.is_empty():
		result.message = "missing_shop_id"
		return result
	if not _shop_definitions.has(shop_id):
		result.message = "shop_open_failed"
		return result

	ensure_shop_inventory(shop_id)
	_current_shop_id = shop_id
	_current_shop_data = _state().shop_inventories[shop_id]

	var scene := preload("res://scenes/ui/shop_screen.tscn")
	_ui_controller = scene.instantiate() as ShopScreen
	_ui_controller.item_selected.connect(_on_item_selected)
	_ui_controller.confirm_pressed.connect(_on_confirm)
	_ui_controller.close_pressed.connect(close_shop)
	_ui_controller.mode_changed.connect(_on_mode_changed)
	_ui_controller.setup(_shop_definitions[shop_id]["name"], InventoryManager.gold)
	_update_item_list(true)

	get_tree().root.add_child(_ui_controller)
	get_tree().paused = true
	UIRouter.register_modal("shop", Callable(self, "close_shop"), 80, true)

	result.success = true
	result.message = "shop_opened"
	result.data = {"shop_id": shop_id, "source_id": source_id}

	shop_opened.emit(shop_id)
	GameEvents.emit_domain_event("shop_opened", {"shop_id": shop_id})
	GameEvents.emit_domain_event("shop_opened_from_source", result.data)
	return result

func close_shop() -> void:
	if _ui_controller:
		_ui_controller.queue_free()
		_ui_controller = null

	_current_shop_id = ""
	_current_shop_data = {}
	get_tree().paused = false
	UIRouter.unregister_modal("shop")

	shop_closed.emit()
	GameEvents.emit_domain_event("shop_closed", {})

func list_shop_items(shop_id: String) -> Array[Dictionary]:
	if not _shop_definitions.has(shop_id):
		return []

	var inventory: Dictionary = get_shop_inventory(shop_id)
	var result: Array[Dictionary] = []
	for item_id in inventory.get("items", {}):
		var shop_item: Dictionary = inventory["items"][item_id]
		var item_data: Dictionary = shop_item.get("item_data", {}).duplicate(true)
		item_data["item_id"] = item_id
		item_data["quantity"] = int(shop_item.get("quantity", 0))
		item_data["infinite"] = bool(shop_item.get("infinite", false))
		item_data["buy_price"] = int(item_data.get("price", 0) * float(inventory.get("buy_rate", 1.0)))
		result.append(item_data)
	return result

func purchase_item(shop_id: String, item_id: String, quantity: int) -> Dictionary:
	if _current_shop_id != shop_id:
		return {"success": false, "message": "shop_not_open", "data": {}}
	var success: bool = _buy_item(item_id, quantity)
	return {"success": success, "message": "item_purchased" if success else "purchase_failed", "data": {}}

func sell_item(shop_id: String, item_id: String, quantity: int) -> Dictionary:
	if _current_shop_id != shop_id:
		return {"success": false, "message": "shop_not_open", "data": {}}
	var success: bool = _sell_item(item_id, quantity)
	return {"success": success, "message": "item_sold" if success else "sell_failed", "data": {}}

func get_shop_inventory(shop_id: String) -> Dictionary:
	ensure_shop_inventory(shop_id)
	return _state().shop_inventories.get(shop_id, {}).duplicate(true)

func ensure_shop_inventory(shop_id: String) -> void:
	if shop_id.is_empty():
		return
	if not _shop_definitions.has(shop_id):
		return
	if not _state().shop_inventories.has(shop_id):
		_initialize_shop_inventory(shop_id)

func _initialize_shop_inventory(shop_id: String) -> void:
	var definition: Dictionary = _shop_definitions[shop_id]
	var inventory := {"items": {}, "buy_rate": definition["buy_rate"], "sell_rate": definition["sell_rate"]}
	for item_entry in definition.get("items", []):
		if not item_entry is Dictionary:
			continue
		var item_id: String = String(item_entry.get("item_id", ""))
		if item_id.is_empty():
			continue
		inventory["items"][item_id] = {
			"quantity": int(item_entry.get("base_quantity", 0)),
			"infinite": bool(item_entry.get("infinite", false)),
			"item_data": ContentDB.get_item_definition(item_id)
		}
	_state().shop_inventories[shop_id] = inventory

func _on_mode_changed(is_buying: bool) -> void:
	_update_item_list(is_buying)

func _update_item_list(is_buying: bool) -> void:
	if _ui_controller == null:
		return
	_ui_controller.clear_item_list()
	_ui_controller.clear_selection()
	if is_buying:
		_update_buy_list()
	else:
		_update_sell_list()

func _update_buy_list() -> void:
	for item_id in _current_shop_data.get("items", {}):
		var shop_item: Dictionary = _current_shop_data["items"][item_id]
		var item_data: Dictionary = shop_item.get("item_data", {})
		var price: int = int(item_data.get("price", 0) * float(_current_shop_data.get("buy_rate", 1.0)))
		var qty_text := "∞" if bool(shop_item.get("infinite", false)) else str(int(shop_item.get("quantity", 0)))
		var display_text := "%s - %dG (库存:%s)" % [item_data.get("item_name", item_id), price, qty_text]
		_ui_controller.add_item_button(item_id, display_text, item_data.duplicate(true))

func _update_sell_list() -> void:
	for item in InventoryManager.get_all_items():
		var item_id: String = item.get("item_id", "")
		var price: int = int(item.get("price", 0) * float(_current_shop_data.get("sell_rate", 0.5)))
		var display_text := "%s x%d - %dG" % [item.get("item_name", item_id), int(item.get("quantity", 0)), price]
		_ui_controller.add_item_button(item_id, display_text, item.duplicate(true))

func _on_item_selected(item_id: String, item_data: Dictionary) -> void:
	var price: int = 0
	if _ui_controller.is_buying():
		price = int(item_data.get("price", 0) * float(_current_shop_data.get("buy_rate", 1.0)))
		_ui_controller.update_description("%s\n价格: %d 金币" % [item_data.get("description", ""), price])
	else:
		price = int(item_data.get("price", 0) * float(_current_shop_data.get("sell_rate", 0.5)))
		_ui_controller.update_description(
			"%s\n出售价格: %d 金币/个\n拥有: %d"
			% [item_data.get("description", ""), price, int(item_data.get("quantity", 1))]
		)

func _on_confirm() -> void:
	var item_id: String = _ui_controller.get_selected_item()
	if item_id.is_empty():
		_ui_controller.update_description("请先选择物品")
		return

	var quantity: int = _ui_controller.get_quantity()
	var success: bool = false
	if _ui_controller.is_buying():
		success = _buy_item(item_id, quantity)
	else:
		success = _sell_item(item_id, quantity)

	if success:
		_ui_controller.update_gold(InventoryManager.gold)
		_update_item_list(_ui_controller.is_buying())

func _buy_item(item_id: String, quantity: int) -> bool:
	if not _current_shop_data.get("items", {}).has(item_id):
		return false
	var shop_item: Dictionary = _current_shop_data["items"][item_id]
	var item_data: Dictionary = shop_item.get("item_data", {})

	if not bool(shop_item.get("infinite", false)) and int(shop_item.get("quantity", 0)) < quantity:
		_ui_controller.update_description("库存不足")
		return false

	var price: int = int(item_data.get("price", 0) * float(_current_shop_data.get("buy_rate", 1.0)) * quantity)
	if InventoryManager.gold < price:
		_ui_controller.update_description("金币不足")
		return false

	if not _can_add_to_inventory(item_data, quantity):
		_ui_controller.update_description("背包已满")
		return false

	InventoryManager.spend_gold(price)
	InventoryManager.add_item(item_data, quantity)
	if not bool(shop_item.get("infinite", false)):
		shop_item["quantity"] = int(shop_item.get("quantity", 0)) - quantity
		_current_shop_data["items"][item_id] = shop_item
		_state().shop_inventories[_current_shop_id] = _current_shop_data

	item_purchased.emit(item_id, quantity, price)
	GameEvents.emit_domain_event(
		"shop_item_purchased",
		{"shop_id": _current_shop_id, "item_id": item_id, "quantity": quantity, "price": price}
	)
	return true

func _sell_item(item_id: String, quantity: int) -> bool:
	var owned: int = InventoryManager.get_item_count_by_id(item_id)
	if owned < quantity:
		_ui_controller.update_description("物品数量不足")
		return false

	var item_data: Dictionary = InventoryManager.get_item_data(item_id)
	var price: int = int(item_data.get("price", 0) * float(_current_shop_data.get("sell_rate", 0.5)) * quantity)
	InventoryManager.remove_item_by_id(item_id, quantity)
	InventoryManager.add_gold(price)

	item_sold.emit(item_id, quantity, price)
	GameEvents.emit_domain_event(
		"shop_item_sold",
		{"shop_id": _current_shop_id, "item_id": item_id, "quantity": quantity, "price": price}
	)
	return true

func _can_add_to_inventory(item_data: Dictionary, quantity: int) -> bool:
	var item_id: String = item_data.get("item_id", item_data.get("item_name", "unknown"))
	if InventoryManager.has_item_id(item_id):
		var current_qty: int = InventoryManager.get_item_count_by_id(item_id)
		var max_stack: int = int(item_data.get("max_stack", GameConstants.MAX_STACK_SIZE))
		if bool(item_data.get("stackable", true)) and current_qty + quantity <= max_stack:
			return true
	return InventoryManager.item_quantities.size() < GameConstants.MAX_UNIQUE_ITEMS
