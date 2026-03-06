extends Node

signal shop_opened(shop_id: String)
signal shop_closed
signal item_purchased(item_id: String, quantity: int, price: int)
signal item_sold(item_id: String, quantity: int, price: int)
signal purchase_failed(item_id: String, reason: String)

# 商店库存：shop_id -> items
var shop_inventories: Dictionary = {}

# 当前打开的商店
var current_shop_id: String = ""
var current_shop_data: Dictionary = {}

# 商店定义（商品列表和基础设置）
var shop_definitions: Dictionary = {}

# UI 引用
var _shop_panel: Panel = null
var _item_list: VBoxContainer = null
var _shop_name_label: Label = null
var _gold_label: Label = null
var _desc_label: Label = null
var _selected_item_id: String = ""
var _is_buying: bool = true

func _ready() -> void:
	_initialize_shops()
	# 确保在暂停时也能处理输入
	process_mode = Node.PROCESS_MODE_ALWAYS

func _initialize_shops() -> void:
	# 商人商店定义
	shop_definitions["merchant_shop"] = {
		"name": "神秘商店",
		"items": [
			{"item_id": "iron_sword", "base_quantity": 1, "infinite": false},
			{"item_id": "health_potion", "base_quantity": 10, "infinite": true},
			{"item_id": "mana_potion", "base_quantity": 5, "infinite": true},
			{"item_id": "leather_armor", "base_quantity": 1, "infinite": false}
		],
		"buy_rate": 1.0,    # 购买价格倍率
		"sell_rate": 0.5    # 出售价格倍率
	}

# 打开商店
func open_shop(shop_id: String) -> bool:
	if not shop_definitions.has(shop_id):
		push_error("商店不存在: " + shop_id)
		return false
	
	# 初始化商店库存（如果是第一次打开）
	if not shop_inventories.has(shop_id):
		_initialize_shop_inventory(shop_id)
	
	current_shop_id = shop_id
	current_shop_data = shop_inventories[shop_id]
	
	# 创建UI
	_create_shop_ui()
	_update_shop_ui()
	
	# 暂停游戏
	get_tree().paused = true
	
	shop_opened.emit(shop_id)
	print("商店已打开: ", shop_definitions[shop_id]["name"])
	return true

# 创建商店UI
func _create_shop_ui() -> void:
	if _shop_panel:
		_shop_panel.queue_free()
	
	# 创建主面板
	_shop_panel = Panel.new()
	_shop_panel.name = "ShopPanel"
	_shop_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	_shop_panel.custom_minimum_size = Vector2(500, 600)
	_shop_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 20)
	_shop_panel.add_child(main_vbox)
	
	# 商店标题
	_shop_name_label = Label.new()
	_shop_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_shop_name_label.add_theme_font_size_override("font_size", 24)
	main_vbox.add_child(_shop_name_label)
	
	# 金币显示
	_gold_label = Label.new()
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_gold_label)
	
	# 分隔
	main_vbox.add_child(HSeparator.new())
	
	# 模式切换按钮
	var mode_hbox = HBoxContainer.new()
	mode_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(mode_hbox)
	
	var buy_btn = Button.new()
	buy_btn.text = "购买"
	buy_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	buy_btn.pressed.connect(func(): _set_buy_mode(true))
	mode_hbox.add_child(buy_btn)
	
	var sell_btn = Button.new()
	sell_btn.text = "出售"
	sell_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sell_btn.pressed.connect(func(): _set_buy_mode(false))
	mode_hbox.add_child(sell_btn)
	
	# 物品列表
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(scroll)
	
	_item_list = VBoxContainer.new()
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_item_list)
	
	# 描述标签
	_desc_label = Label.new()
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(0, 60)
	main_vbox.add_child(_desc_label)
	
	# 数量选择
	var quantity_hbox = HBoxContainer.new()
	main_vbox.add_child(quantity_hbox)
	
	var qty_label = Label.new()
	qty_label.text = "数量:"
	quantity_hbox.add_child(qty_label)
	
	var qty_spin = SpinBox.new()
	qty_spin.min_value = 1
	qty_spin.max_value = 99
	qty_spin.value = 1
	qty_spin.name = "QuantitySpin"
	qty_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quantity_hbox.add_child(qty_spin)
	
	# 操作按钮
	var action_hbox = HBoxContainer.new()
	action_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(action_hbox)
	
	var confirm_btn = Button.new()
	confirm_btn.text = "确认"
	confirm_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_btn.pressed.connect(_on_confirm_transaction)
	action_hbox.add_child(confirm_btn)
	
	var close_btn = Button.new()
	close_btn.text = "关闭"
	close_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close_btn.pressed.connect(close_shop)
	action_hbox.add_child(close_btn)
	
	# 添加到场景树
	get_tree().root.add_child(_shop_panel)

# 更新商店UI
func _update_shop_ui() -> void:
	if not _shop_panel:
		return
	
	var shop_info = get_current_shop_info()
	_shop_name_label.text = shop_info.get("name", "商店")
	_gold_label.text = "金币: %d" % InventoryManager.gold
	_desc_label.text = "选择物品进行交易"
	_selected_item_id = ""
	
	_update_item_list()

# 设置购买/出售模式
func _set_buy_mode(buying: bool) -> void:
	_is_buying = buying
	_selected_item_id = ""
	_desc_label.text = "选择物品进行%s" % ("购买" if buying else "出售")
	_update_item_list()

# 更新物品列表
func _update_item_list() -> void:
	if not _item_list:
		return
	
	# 清除旧按钮
	for child in _item_list.get_children():
		child.queue_free()
	
	if _is_buying:
		_update_buy_list()
	else:
		_update_sell_list()

# 更新购买列表
func _update_buy_list() -> void:
	var items = get_shop_items()
	
	if items.is_empty():
		var label = Label.new()
		label.text = "商店暂无商品"
		_item_list.add_child(label)
		return
	
	for item in items:
		var button = Button.new()
		var item_name = item.get("name", "未知")
		var price = item.get("price", 0)
		var quantity = item.get("quantity", 0)
		var infinite = item.get("infinite", false)
		var item_id = item.get("item_id", "")
		
		var qty_text = "∞" if infinite else str(quantity)
		button.text = "%s - %dG (库存:%s)" % [item_name, price, qty_text]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# 使用 bind 避免闭包问题
		button.pressed.connect(_on_item_selected.bind(item_id, item.duplicate()))
		
		_item_list.add_child(button)

# 更新出售列表
func _update_sell_list() -> void:
	var items = InventoryManager.get_all_items()
	
	if items.is_empty():
		var label = Label.new()
		label.text = "背包为空"
		_item_list.add_child(label)
		return
	
	for item in items:
		var button = Button.new()
		var item_name = item.get("item_name", "未知")
		var quantity = item.get("quantity", 0)
		var price = item.get("price", 0)
		var item_id = item.get("item_id", "")
		
		# 计算出售价格（50%）
		var shop = shop_inventories[current_shop_id]
		var sell_price = int(price * shop["sell_rate"])
		
		button.text = "%s x%d - %dG" % [item_name, quantity, sell_price]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		# 使用 bind 避免闭包问题
		button.pressed.connect(_on_item_selected_sell.bind(item_id, item.duplicate(), sell_price))
		
		_item_list.add_child(button)

# 选择购买物品
func _on_item_selected(item_id: String, item_data: Dictionary) -> void:
	_selected_item_id = item_id
	var desc = item_data.get("description", "")
	var price = item_data.get("price", 0)
	_desc_label.text = "%s\n价格: %d 金币" % [desc, price]

# 选择出售物品
func _on_item_selected_sell(item_id: String, item_data: Dictionary, sell_price: int) -> void:
	_selected_item_id = item_id
	var desc = item_data.get("description", "")
	var qty = item_data.get("quantity", 1)
	_desc_label.text = "%s\n出售价格: %d 金币/个\n拥有: %d" % [desc, sell_price, qty]

# 确认交易
func _on_confirm_transaction() -> void:
	if _selected_item_id.is_empty():
		_desc_label.text = "请先选择物品"
		return
	
	# 查找 QuantitySpin 节点（可能在任意子节点中）
	var quantity = 1
	for child in _shop_panel.get_children():
		quantity = _find_spinbox_value(child)
		if quantity > 1:
			break
	
	if _is_buying:
		buy_item(_selected_item_id, quantity)
	else:
		sell_item(_selected_item_id, quantity)
	
	# 刷新UI
	_update_shop_ui()

func _find_spinbox_value(node: Node) -> int:
	if node is SpinBox and node.name == "QuantitySpin":
		return int(node.value)
	for child in node.get_children():
		var result = _find_spinbox_value(child)
		if result > 1:
			return result
	return 1

# 关闭商店
func close_shop() -> void:
	if _shop_panel:
		_shop_panel.queue_free()
		_shop_panel = null
	
	current_shop_id = ""
	current_shop_data = {}
	_selected_item_id = ""
	
	# 恢复游戏
	get_tree().paused = false
	
	shop_closed.emit()
	print("商店已关闭")

func _input(event: InputEvent) -> void:
	if _shop_panel and _shop_panel.visible and event.is_action_pressed("ui_cancel"):
		close_shop()
		get_viewport().set_input_as_handled()

# 购买物品
func buy_item(item_id: String, quantity: int = 1) -> bool:
	if current_shop_id.is_empty():
		push_warning("没有打开的商店")
		return false
	
	var shop = shop_inventories[current_shop_id]
	
	if not shop["items"].has(item_id):
		purchase_failed.emit(item_id, "商店没有此商品")
		return false
	
	var shop_item = shop["items"][item_id]
	var item_data = shop_item["item_data"]
	
	# 检查库存
	if not shop_item["infinite"] and shop_item["quantity"] < quantity:
		purchase_failed.emit(item_id, "库存不足")
		return false
	
	# 计算价格
	var base_price = item_data.get("price", 0)
	var final_price = int(base_price * shop["buy_rate"] * quantity)
	
	# 检查金币
	if InventoryManager.gold < final_price:
		purchase_failed.emit(item_id, "金币不足")
		return false
	
	# 检查背包空间
	if not _can_add_to_inventory(item_data, quantity):
		purchase_failed.emit(item_id, "背包已满")
		return false
	
	# 执行交易
	InventoryManager.spend_gold(final_price)
	InventoryManager.add_item(item_data, quantity)
	
	if not shop_item["infinite"]:
		shop_item["quantity"] -= quantity
	
	item_purchased.emit(item_id, quantity, final_price)
	print("购买成功: %s x%d, 花费 %d 金币" % [item_data.get("item_name", item_id), quantity, final_price])
	return true

# 出售物品
func sell_item(item_id: String, quantity: int = 1) -> bool:
	if current_shop_id.is_empty():
		push_warning("没有打开的商店")
		return false
	
	var shop = shop_inventories[current_shop_id]
	
	# 检查玩家是否有此物品
	if not InventoryManager.has_item_id(item_id):
		push_warning("玩家没有此物品: " + item_id)
		return false
	
	var player_quantity = InventoryManager.get_item_count_by_id(item_id)
	if player_quantity < quantity:
		push_warning("物品数量不足")
		return false
	
	var item_data = InventoryManager.get_item_data(item_id)
	var base_price = item_data.get("price", 0)
	var sell_price = int(base_price * shop["sell_rate"] * quantity)
	
	# 执行交易
	InventoryManager.remove_item_by_id(item_id, quantity)
	InventoryManager.add_gold(sell_price)
	
	item_sold.emit(item_id, quantity, sell_price)
	print("出售成功: %s x%d, 获得 %d 金币" % [item_data.get("item_name", item_id), quantity, sell_price])
	return true

# 检查是否可以添加到背包
func _can_add_to_inventory(item_data: Dictionary, quantity: int) -> bool:
	var item_id = _get_item_id(item_data)
	
	# 如果已有此物品且可堆叠
	if InventoryManager.has_item_id(item_id):
		var current_qty = InventoryManager.get_item_count_by_id(item_id)
		var max_stack = item_data.get("max_stack", 99)
		if item_data.get("stackable", true) and current_qty + quantity <= max_stack:
			return true
	
	# 检查唯一物品上限
	var unique_items = InventoryManager.item_quantities.size()
	if unique_items >= InventoryManager.MAX_UNIQUE_ITEMS:
		return false
	
	return true

# 获取商店商品列表
func get_shop_items() -> Array[Dictionary]:
	if current_shop_id.is_empty():
		return []
	
	var result: Array[Dictionary] = []
	var shop = shop_inventories[current_shop_id]
	
	for item_id in shop["items"]:
		var shop_item = shop["items"][item_id]
		var item_data = shop_item["item_data"]
		var base_price = item_data.get("price", 0)
		var final_price = int(base_price * shop["buy_rate"])
		
		result.append({
			"item_id": item_id,
			"name": item_data.get("item_name", item_id),
			"description": item_data.get("description", ""),
			"price": final_price,
			"quantity": shop_item["quantity"] if not shop_item["infinite"] else -1,
			"infinite": shop_item["infinite"],
			"item_type": item_data.get("item_type", 0),
			"icon": item_data.get("icon", null)
		})
	
	return result

# 获取当前商店信息
func get_current_shop_info() -> Dictionary:
	if current_shop_id.is_empty():
		return {}
	
	var definition = shop_definitions[current_shop_id]
	return {
		"id": current_shop_id,
		"name": definition.get("name", "商店"),
		"buy_rate": current_shop_data.get("buy_rate", 1.0),
		"sell_rate": current_shop_data.get("sell_rate", 0.5)
	}

# 补充商店库存（用于每日刷新等）
func restock_shop(shop_id: String) -> void:
	if shop_inventories.has(shop_id):
		shop_inventories.erase(shop_id)
	_initialize_shop_inventory(shop_id)
	print("商店 %s 已补货" % shop_id)

# 添加新商店定义
func add_shop_definition(shop_id: String, definition: Dictionary) -> void:
	shop_definitions[shop_id] = definition.duplicate(true)

# 获取物品ID（辅助函数）
func _get_item_id(item_data: Dictionary) -> String:
	return item_data.get("item_id", item_data.get("item_name", "unknown"))

# 获取物品数据（从统一的数据源）
func _get_item_data_by_id(item_id: String) -> Dictionary:
	# 基础物品数据库
	var items = {
		"iron_sword": {
			"item_id": "iron_sword",
			"item_name": "铁剑",
			"description": "一把普通的铁剑",
			"item_type": 1,  # EQUIPMENT
			"equipment_slot": 1,  # WEAPON
			"attack": 5,
			"defense": 0,
			"price": 100,
			"stackable": false,
			"max_stack": 1
		},
		"health_potion": {
			"item_id": "health_potion",
			"item_name": "生命药水",
			"description": "恢复30点生命值",
			"item_type": 0,  # CONSUMABLE
			"heal_amount": 30,
			"price": 20,
			"stackable": true,
			"max_stack": 99
		},
		"mana_potion": {
			"item_id": "mana_potion",
			"item_name": "魔法药水",
			"description": "恢复20点魔法值",
			"item_type": 0,
			"restore_mana_amount": 20,
			"price": 15,
			"stackable": true,
			"max_stack": 99
		},
		"leather_armor": {
			"item_id": "leather_armor",
			"item_name": "皮甲",
			"description": "基础的皮制护甲",
			"item_type": 1,
			"equipment_slot": 2,  # ARMOR
			"attack": 0,
			"defense": 3,
			"price": 80,
			"stackable": false,
			"max_stack": 1
		},
		"magic_dagger": {
			"item_id": "magic_dagger",
			"item_name": "魔法匕首",
			"description": "附有魔法的匕首",
			"item_type": 1,
			"equipment_slot": 1,
			"attack": 8,
			"defense": 0,
			"price": 200,
			"stackable": false,
			"max_stack": 1
		}
	}
	
	return items.get(item_id, {})

# 初始化商店库存
func _initialize_shop_inventory(shop_id: String) -> void:
	var definition = shop_definitions[shop_id]
	var inventory = {
		"items": {},
		"buy_rate": definition.get("buy_rate", 1.0),
		"sell_rate": definition.get("sell_rate", 0.5)
	}
	
	for item_entry in definition["items"]:
		var item_id = item_entry["item_id"]
		inventory["items"][item_id] = {
			"quantity": item_entry.get("base_quantity", 1),
			"infinite": item_entry.get("infinite", false),
			"item_data": _get_item_data_by_id(item_id)
		}
	
	shop_inventories[shop_id] = inventory

# 存档数据
func get_save_data() -> Dictionary:
	return {
		"shop_inventories": shop_inventories.duplicate(true)
	}

# 读档数据
func load_save_data(data: Dictionary) -> void:
	if data.has("shop_inventories"):
		shop_inventories = data["shop_inventories"].duplicate(true)
		print("商店数据已加载，商店数量: ", shop_inventories.size())
