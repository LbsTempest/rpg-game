class_name ShopUI
extends Control

signal item_purchased(item_id: String, quantity: int)
signal item_sold(item_id: String, quantity: int)
signal shop_closed

@onready var shop_name_label: Label = $Panel/ShopNameLabel
@onready var gold_label: Label = $Panel/GoldLabel
@onready var item_list: VBoxContainer = $Panel/ScrollContainer/ItemList
@onready var description_label: Label = $Panel/DescriptionLabel
@onready var close_button: Button = $Panel/CloseButton
@onready var buy_button: Button = $Panel/BuyButton
@onready var sell_button: Button = $Panel/SellButton
@onready var quantity_spin: SpinBox = $Panel/QuantitySpinBox

var current_shop_id: String = ""
var selected_item_id: String = ""
var is_buying: bool = true

func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	buy_button.pressed.connect(_on_buy_mode)
	sell_button.pressed.connect(_on_sell_mode)
	visible = false

func open_shop(shop_id: String) -> void:
	current_shop_id = shop_id
	selected_item_id = ""
	is_buying = true
	
	var shop_info = ShopManager.get_current_shop_info()
	shop_name_label.text = shop_info.get("name", "商店")
	
	_update_gold_display()
	_update_item_list()
	
	visible = true
	process_mode = Node.PROCESS_MODE_ALWAYS

func close_shop() -> void:
	visible = false
	ShopManager.close_shop()
	shop_closed.emit()

func _update_gold_display() -> void:
	gold_label.text = "金币: %d" % InventoryManager.gold

func _update_item_list() -> void:
	# 清除旧项目
	for child in item_list.get_children():
		child.queue_free()
	
	if is_buying:
		_update_buy_list()
	else:
		_update_sell_list()

func _update_buy_list() -> void:
	var items = ShopManager.get_shop_items()
	
	if items.is_empty():
		var label = Label.new()
		label.text = "商店暂无商品"
		item_list.add_child(label)
		return
	
	for item in items:
		var button = Button.new()
		var item_name = item.get("name", "未知")
		var price = item.get("price", 0)
		var quantity = item.get("quantity", 0)
		var infinite = item.get("infinite", false)
		
		var qty_text = "∞" if infinite else str(quantity)
		button.text = "%s - %dG (%s)" % [item_name, price, qty_text]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var item_id = item.get("item_id", "")
		button.pressed.connect(func(): _on_item_selected(item_id, item))
		
		item_list.add_child(button)

func _update_sell_list() -> void:
	var items = InventoryManager.get_all_items()
	
	if items.is_empty():
		var label = Label.new()
		label.text = "背包为空"
		item_list.add_child(label)
		return
	
	for item in items:
		var button = Button.new()
		var item_name = item.get("item_name", "未知")
		var quantity = item.get("quantity", 0)
		var price = item.get("price", 0)
		
		# 计算出售价格（50%）
		var sell_price = int(price * 0.5)
		
		button.text = "%s x%d - %dG" % [item_name, quantity, sell_price]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		
		var item_id = item.get("item_id", "")
		button.pressed.connect(func(): _on_item_selected(item_id, item))
		
		item_list.add_child(button)

func _on_item_selected(item_id: String, item_data: Dictionary) -> void:
	selected_item_id = item_id
	
	if is_buying:
		var desc = item_data.get("description", "")
		var price = item_data.get("price", 0)
		description_label.text = "%s\n价格: %d 金币" % [desc, price]
		quantity_spin.max_value = 99
	else:
		var desc = item_data.get("description", "")
		var price = item_data.get("price", 0)
		var sell_price = int(price * 0.5)
		var qty = item_data.get("quantity", 1)
		description_label.text = "%s\n出售价格: %d 金币/个\n拥有: %d" % [desc, sell_price, qty]
		quantity_spin.max_value = qty

func _on_buy_mode() -> void:
	is_buying = true
	buy_button.disabled = true
	sell_button.disabled = false
	selected_item_id = ""
	description_label.text = "选择要购买的物品"
	_update_item_list()

func _on_sell_mode() -> void:
	is_buying = false
	buy_button.disabled = false
	sell_button.disabled = true
	selected_item_id = ""
	description_label.text = "选择要出售的物品"
	_update_item_list()

func _on_close_pressed() -> void:
	close_shop()

func _process(delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		close_shop()
