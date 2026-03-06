extends Node

signal shop_opened(shop_id: String)
signal shop_closed
signal item_purchased(item_id: String, quantity: int, price: int)
signal item_sold(item_id: String, quantity: int, price: int)

var shop_inventories: Dictionary = {}
var shop_definitions: Dictionary = {}

var _current_shop_id: String = ""
var _current_shop_data: Dictionary = {}
var _ui_controller = null

func _ready() -> void:
	_initialize_shops()

func _initialize_shops() -> void:
	shop_definitions[GameConstants.SHOP_MERCHANT] = {
		"name": "神秘商店",
		"items": [
			{"item_id": "iron_sword", "base_quantity": 1, "infinite": false},
			{"item_id": "health_potion", "base_quantity": 10, "infinite": true},
			{"item_id": "mana_potion", "base_quantity": 5, "infinite": true},
			{"item_id": "leather_armor", "base_quantity": 1, "infinite": false}
		],
		"buy_rate": GameConstants.SHOP_BUY_RATE,
		"sell_rate": GameConstants.SHOP_SELL_RATE
	}

func open_shop(shop_id: String) -> bool:
	if not shop_definitions.has(shop_id):
		push_error("Shop not found: " + shop_id)
		return false
	
	if not shop_inventories.has(shop_id):
		_initialize_shop_inventory(shop_id)
	
	_current_shop_id = shop_id
	_current_shop_data = shop_inventories[shop_id]
	
	var scene = preload("res://scenes/shop_ui.tscn")
	_ui_controller = scene.instantiate()
	_ui_controller.item_selected.connect(_on_item_selected)
	_ui_controller.confirm_pressed.connect(_on_confirm)
	_ui_controller.close_pressed.connect(close_shop)
	_ui_controller.mode_changed.connect(_on_mode_changed)
	
	var shop_def = shop_definitions[shop_id]
	_ui_controller.setup(shop_def["name"], InventoryManager.gold)
	
	_update_item_list(true)
	
	get_tree().root.add_child(_ui_controller)
	get_tree().paused = true
	
	shop_opened.emit(shop_id)
	return true

func close_shop() -> void:
	if _ui_controller:
		_ui_controller.queue_free()
		_ui_controller = null
	
	_current_shop_id = ""
	_current_shop_data = {}
	
	get_tree().paused = false
	shop_closed.emit()

func _on_mode_changed(is_buying: bool) -> void:
	_update_item_list(is_buying)

func _update_item_list(is_buying: bool) -> void:
	_ui_controller.clear_item_list()
	_ui_controller.clear_selection()
	
	if is_buying:
		_update_buy_list()
	else:
		_update_sell_list()

func _update_buy_list() -> void:
	for item_id in _current_shop_data["items"]:
		var shop_item = _current_shop_data["items"][item_id]
		var item_data = shop_item["item_data"]
		var price = int(item_data["price"] * _current_shop_data["buy_rate"])
		var qty_text = "∞" if shop_item["infinite"] else str(shop_item["quantity"])
		var display_text = "%s - %dG (库存:%s)" % [item_data["item_name"], price, qty_text]
		_ui_controller.add_item_button(item_id, display_text, item_data.duplicate())

func _update_sell_list() -> void:
	for item in InventoryManager.get_all_items():
		var item_id = item["item_id"]
		var price = int(item["price"] * _current_shop_data["sell_rate"])
		var display_text = "%s x%d - %dG" % [item["item_name"], item["quantity"], price]
		_ui_controller.add_item_button(item_id, display_text, item.duplicate())

func _on_item_selected(item_id: String, item_data: Dictionary) -> void:
	var price
	if _ui_controller.is_buying():
		price = int(item_data["price"] * _current_shop_data["buy_rate"])
		_ui_controller.update_description("%s\n价格: %d 金币" % [item_data.get("description", ""), price])
	else:
		price = int(item_data["price"] * _current_shop_data["sell_rate"])
		_ui_controller.update_description("%s\n出售价格: %d 金币/个\n拥有: %d" % [item_data.get("description", ""), price, item_data.get("quantity", 1)])

func _on_confirm() -> void:
	var item_id = _ui_controller.get_selected_item()
	if item_id.is_empty():
		_ui_controller.update_description("请先选择物品")
		return
	
	var quantity = _ui_controller.get_quantity()
	var success
	
	if _ui_controller.is_buying():
		success = _buy_item(item_id, quantity)
	else:
		success = _sell_item(item_id, quantity)
	
	if success:
		_ui_controller.update_gold(InventoryManager.gold)
		_update_item_list(_ui_controller.is_buying())

func _buy_item(item_id: String, quantity: int) -> bool:
	var shop_item = _current_shop_data["items"][item_id]
	var item_data = shop_item["item_data"]
	
	if not shop_item["infinite"] and shop_item["quantity"] < quantity:
		_ui_controller.update_description("库存不足")
		return false
	
	var price = int(item_data["price"] * _current_shop_data["buy_rate"] * quantity)
	
	if InventoryManager.gold < price:
		_ui_controller.update_description("金币不足")
		return false
	
	if not _can_add_to_inventory(item_data, quantity):
		_ui_controller.update_description("背包已满")
		return false
	
	InventoryManager.spend_gold(price)
	InventoryManager.add_item(item_data, quantity)
	
	if not shop_item["infinite"]:
		shop_item["quantity"] -= quantity
	
	item_purchased.emit(item_id, quantity, price)
	return true

func _sell_item(item_id: String, quantity: int) -> bool:
	var current_qty = InventoryManager.get_item_count_by_id(item_id)
	if current_qty < quantity:
		_ui_controller.update_description("物品数量不足")
		return false
	
	var item_data = InventoryManager.get_item_data(item_id)
	var price = int(item_data["price"] * _current_shop_data["sell_rate"] * quantity)
	
	InventoryManager.remove_item_by_id(item_id, quantity)
	InventoryManager.add_gold(price)
	
	item_sold.emit(item_id, quantity, price)
	return true

func _can_add_to_inventory(item_data: Dictionary, quantity: int) -> bool:
	var item_id = item_data.get("item_id", item_data.get("item_name", "unknown"))
	
	if InventoryManager.has_item_id(item_id):
		var current_qty = InventoryManager.get_item_count_by_id(item_id)
		var max_stack = item_data.get("max_stack", GameConstants.MAX_STACK_SIZE)
		if item_data.get("stackable", true) and current_qty + quantity <= max_stack:
			return true
	
	return InventoryManager.item_quantities.size() < GameConstants.MAX_UNIQUE_ITEMS

func _initialize_shop_inventory(shop_id: String) -> void:
	var definition = shop_definitions[shop_id]
	var inventory = {
		"items": {},
		"buy_rate": definition["buy_rate"],
		"sell_rate": definition["sell_rate"]
	}
	
	for item_entry in definition["items"]:
		var item_id = item_entry["item_id"]
		inventory["items"][item_id] = {
			"quantity": item_entry["base_quantity"],
			"infinite": item_entry["infinite"],
			"item_data": _get_item_data(item_id)
		}
	
	shop_inventories[shop_id] = inventory

func _get_item_data(item_id: String) -> Dictionary:
	var items = {
		"iron_sword": {"item_id": "iron_sword", "item_name": "铁剑", "description": "一把普通的铁剑", "item_type": GameConstants.ITEM_TYPE_EQUIPMENT, "equipment_slot": GameConstants.SLOT_WEAPON, "attack": 5, "price": 100, "stackable": false, "max_stack": 1},
		"health_potion": {"item_id": "health_potion", "item_name": "生命药水", "description": "恢复30点生命值", "item_type": GameConstants.ITEM_TYPE_CONSUMABLE, "heal_amount": 30, "price": 20, "stackable": true, "max_stack": 99},
		"mana_potion": {"item_id": "mana_potion", "item_name": "魔法药水", "description": "恢复20点魔法值", "item_type": GameConstants.ITEM_TYPE_CONSUMABLE, "restore_mana_amount": 20, "price": 15, "stackable": true, "max_stack": 99},
		"leather_armor": {"item_id": "leather_armor", "item_name": "皮甲", "description": "基础的皮制护甲", "item_type": GameConstants.ITEM_TYPE_EQUIPMENT, "equipment_slot": GameConstants.SLOT_ARMOR, "defense": 3, "price": 80, "stackable": false, "max_stack": 1}
	}
	return items.get(item_id, {})

func get_save_data() -> Dictionary:
	return {"shop_inventories": shop_inventories.duplicate(true)}

func load_save_data(data: Dictionary) -> void:
	if data.has("shop_inventories"):
		shop_inventories = data["shop_inventories"].duplicate(true)

func reset_all() -> void:
	shop_inventories.clear()

func _input(event: InputEvent) -> void:
	if _ui_controller and event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()
