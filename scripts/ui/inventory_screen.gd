class_name InventoryScreen
extends PanelContainer

@onready var items_grid: GridContainer = $InventoryVBox/ItemsScroll/ItemsGrid
@onready var close_button: Button = $InventoryVBox/CloseButton

var _is_open: bool = false
var _player: Node = null

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close_screen)

func set_player(player_node: Node) -> void:
	_player = player_node

func open_screen() -> void:
	if _is_open:
		return
	_is_open = true
	visible = true
	App.is_inventory_open = true
	UIRouter.register_modal("inventory", Callable(self, "close_screen"), 20, true)
	refresh()

func close_screen() -> void:
	if not _is_open:
		return
	_is_open = false
	visible = false
	App.is_inventory_open = false
	UIRouter.unregister_modal("inventory")

func toggle_screen() -> void:
	if _is_open:
		close_screen()
	else:
		open_screen()

func refresh() -> void:
	for child in items_grid.get_children():
		child.queue_free()

	var all_items: Array[Dictionary] = InventoryService.get_all_items()
	for item_data in all_items:
		_create_item_button(item_data)

	for slot in [GameConstants.SLOT_WEAPON, GameConstants.SLOT_ARMOR, GameConstants.SLOT_ACCESSORY]:
		var equipped: Dictionary = InventoryService.get_equipped_item(slot)
		if not equipped.is_empty():
			_create_equipped_button(equipped, slot)

func _create_item_button(item_data: Dictionary) -> void:
	var button := Button.new()
	var item_name: String = item_data.get("item_name", item_data.get("display_name", "Unknown"))
	var quantity: int = int(item_data.get("quantity", 1))
	var item_type: int = int(item_data.get("item_type", GameConstants.ITEM_TYPE_CONSUMABLE))

	button.text = "%s x%d" % [item_name, quantity]
	button.custom_minimum_size = Vector2(80, 80)

	if item_type == GameConstants.ITEM_TYPE_EQUIPMENT:
		button.pressed.connect(_on_equip_item.bind(item_data))
	elif item_type == GameConstants.ITEM_TYPE_CONSUMABLE:
		button.pressed.connect(_on_use_item.bind(item_data))

	items_grid.add_child(button)

func _create_equipped_button(item_data: Dictionary, slot: int) -> void:
	var button := Button.new()
	button.text = "[E] %s" % item_data.get("item_name", item_data.get("display_name", "Unknown"))
	button.custom_minimum_size = Vector2(80, 80)
	button.modulate = Color(0.8, 1.0, 0.8)
	button.pressed.connect(_on_unequip_item.bind(slot))
	items_grid.add_child(button)

func _on_equip_item(item_data: Dictionary) -> void:
	InventoryService.equip_item(item_data)
	refresh()

func _on_unequip_item(slot: int) -> void:
	InventoryService.unequip_item(slot)
	refresh()

func _on_use_item(item_data: Dictionary) -> void:
	var target_player: Node = _player
	if target_player == null:
		target_player = Utils.get_group_node("player")
	if target_player == null:
		return

	var heal_amount: int = _get_effect_value(item_data, "heal_amount")
	var restore_mana_amount: int = _get_effect_value(item_data, "restore_mana_amount")
	var used: bool = false

	if heal_amount > 0 and target_player.current_health < target_player.max_health:
		target_player.heal(heal_amount)
		used = true

	if restore_mana_amount > 0 and target_player.current_mana < target_player.max_mana:
		target_player.restore_mana(restore_mana_amount)
		used = true

	if used:
		var item_id: String = item_data.get("item_id", item_data.get("item_name", "unknown"))
		InventoryService.remove_item_by_id(item_id, 1)
		refresh()

func _get_effect_value(item_data: Dictionary, key: String) -> int:
	if item_data.has(key):
		return int(item_data.get(key, 0))
	var effects: Dictionary = item_data.get("effects", {})
	if effects.has(key):
		return int(effects.get(key, 0))
	return 0
