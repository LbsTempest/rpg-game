class_name ShopScreen
extends Panel

signal item_selected(item_id: String, item_data: Dictionary)
signal confirm_pressed
signal close_pressed
signal mode_changed(is_buying: bool)

var title_label: Label
var gold_label: Label
var item_list: VBoxContainer
var desc_label: Label
var quantity_spin: SpinBox
var buy_button: Button
var sell_button: Button
var confirm_button: Button
var close_button: Button

var _is_buying: bool = true
var _selected_item_id: String = ""
var _selected_item_data: Dictionary = {}
var _initialized: bool = false

func _ready() -> void:
	_ensure_initialized()

func _ensure_initialized() -> void:
	if _initialized:
		return

	title_label = get_node("VBoxContainer/TitleLabel")
	gold_label = get_node("VBoxContainer/GoldLabel")
	item_list = get_node("VBoxContainer/ScrollContainer/ItemList")
	desc_label = get_node("VBoxContainer/DescriptionLabel")
	quantity_spin = get_node("VBoxContainer/QuantityHBox/QuantitySpin")
	buy_button = get_node("VBoxContainer/ModeHBox/BuyButton")
	sell_button = get_node("VBoxContainer/ModeHBox/SellButton")
	confirm_button = get_node("VBoxContainer/ActionHBox/ConfirmButton")
	close_button = get_node("VBoxContainer/ActionHBox/CloseButton")

	buy_button.pressed.connect(_on_buy_mode)
	sell_button.pressed.connect(_on_sell_mode)
	confirm_button.pressed.connect(_on_confirm)
	close_button.pressed.connect(_on_close)

	_initialized = true

func setup(shop_name: String, current_gold: int) -> void:
	_ensure_initialized()
	title_label.text = shop_name
	update_gold(current_gold)
	clear_selection()

func update_gold(amount: int) -> void:
	_ensure_initialized()
	gold_label.text = "金币: %d" % amount

func clear_selection() -> void:
	_ensure_initialized()
	_selected_item_id = ""
	_selected_item_data = {}
	desc_label.text = "选择物品进行交易"

func clear_item_list() -> void:
	_ensure_initialized()
	for child in item_list.get_children():
		child.queue_free()

func add_item_button(item_id: String, display_text: String, item_data: Dictionary) -> void:
	_ensure_initialized()
	var button := Button.new()
	button.text = display_text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_on_item_selected.bind(item_id, item_data))
	item_list.add_child(button)

func update_description(text: String) -> void:
	_ensure_initialized()
	desc_label.text = text

func get_quantity() -> int:
	_ensure_initialized()
	return int(quantity_spin.value)

func get_selected_item() -> String:
	return _selected_item_id

func is_buying() -> bool:
	return _is_buying

func _on_buy_mode() -> void:
	_ensure_initialized()
	_is_buying = true
	_update_mode_buttons()
	mode_changed.emit(true)

func _on_sell_mode() -> void:
	_ensure_initialized()
	_is_buying = false
	_update_mode_buttons()
	mode_changed.emit(false)

func _update_mode_buttons() -> void:
	buy_button.disabled = _is_buying
	sell_button.disabled = not _is_buying
	clear_selection()

func _on_item_selected(item_id: String, item_data: Dictionary) -> void:
	_selected_item_id = item_id
	_selected_item_data = item_data
	item_selected.emit(item_id, item_data)

func _on_confirm() -> void:
	confirm_pressed.emit()

func _on_close() -> void:
	close_pressed.emit()
