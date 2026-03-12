class_name UI
extends CanvasLayer

@onready var hp_bar := $StatsPanel/VBox/HPBar
@onready var hp_label := $StatsPanel/VBox/HPLabel
@onready var mp_bar := $StatsPanel/VBox/MPBar
@onready var mp_label := $StatsPanel/VBox/MPLabel
@onready var exp_label := $StatsPanel/VBox/EXPLabel
@onready var level_label := $StatsPanel/VBox/LevelLabel
@onready var gold_label := $StatsPanel/VBox/GoldLabel
@onready var attack_label := $StatsPanel/VBox/AttackLabel
@onready var defense_label := $StatsPanel/VBox/DefenseLabel

@onready var inventory_button := $ButtonsHBox/InventoryButton
@onready var save_button := $ButtonsHBox/SaveButton
@onready var journal_button := $ButtonsHBox/JournalButton
@onready var load_button := $ButtonsHBox/LoadButton

@onready var inventory_panel := $InventoryPanel
@onready var items_grid := $InventoryPanel/InventoryVBox/ItemsScroll/ItemsGrid
@onready var close_button := $InventoryPanel/InventoryVBox/CloseButton
@onready var journal_screen: JournalScreen = $JournalScreen

var player: Node
var is_inventory_open: bool = false

func _ready() -> void:
	player = Utils.get_group_node("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.mana_changed.connect(_on_mana_changed)
		player.level_up.connect(_on_level_up)
		_update_stats()
	
	InventoryManager.item_added.connect(_on_inventory_changed)
	InventoryManager.item_removed.connect(_on_inventory_changed)
	InventoryManager.equipment_changed.connect(_on_equipment_changed)
	InventoryManager.gold_changed.connect(_on_gold_changed)
	
	inventory_button.pressed.connect(_on_inventory_pressed)
	save_button.pressed.connect(_on_save_pressed)
	journal_button.pressed.connect(_on_journal_pressed)
	load_button.pressed.connect(_on_load_pressed)
	close_button.pressed.connect(_on_close_inventory)
	
	_update_inventory_display()

func _update_stats() -> void:
	if not player:
		return
	
	hp_bar.max_value = player.max_health
	hp_bar.value = player.current_health
	hp_label.text = Utils.format_health(player.current_health, player.max_health)
	
	mp_bar.max_value = player.max_mana
	mp_bar.value = player.current_mana
	mp_label.text = Utils.format_mana(player.current_mana, player.max_mana)
	
	exp_label.text = "经验: %d/%d" % [player.experience, player.experience_to_next_level]
	level_label.text = "等级:%d" % player.level
	
	gold_label.text = Utils.format_gold(InventoryManager.gold)
	
	var base_attack = player.attack
	var equip_attack = InventoryManager.get_total_attack()
	var total_attack = base_attack + equip_attack
	attack_label.text = "攻击: %d (+%d)" % [total_attack, equip_attack] if equip_attack > 0 else "攻击: %d" % total_attack
	
	var base_defense = player.defense
	var equip_defense = InventoryManager.get_total_defense()
	var total_defense = base_defense + equip_defense
	defense_label.text = "防御: %d (+%d)" % [total_defense, equip_defense] if equip_defense > 0 else "防御: %d" % total_defense

func _on_health_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = Utils.format_health(current, maximum)

func _on_mana_changed(current: int, maximum: int) -> void:
	mp_bar.max_value = maximum
	mp_bar.value = current
	mp_label.text = Utils.format_mana(current, maximum)

func _on_level_up(new_level: int) -> void:
	level_label.text = "Lv.%d" % new_level
	exp_label.text = "EXP: %d/%d" % [player.experience, player.experience_to_next_level]

func _on_inventory_changed(item_id: String, amount: int) -> void:
	_update_inventory_display()

func _on_equipment_changed(slot: String, item: Dictionary) -> void:
	_update_stats()

func _on_gold_changed(new_amount: int) -> void:
	gold_label.text = Utils.format_gold(new_amount)

func _on_inventory_pressed() -> void:
	if is_inventory_open:
		_close_inventory()
	else:
		_open_inventory()

func toggle_inventory_from_router() -> void:
	_on_inventory_pressed()

func _open_inventory() -> void:
	is_inventory_open = true
	App.is_inventory_open = true
	inventory_panel.visible = true
	UIRouter.register_modal("inventory", Callable(self, "_close_inventory"), 20, true)
	await get_tree().process_frame
	_update_inventory_display()

func _close_inventory() -> void:
	is_inventory_open = false
	App.is_inventory_open = false
	inventory_panel.visible = false
	UIRouter.unregister_modal("inventory")

func _on_close_inventory() -> void:
	_close_inventory()

func _update_inventory_display() -> void:
	for child in items_grid.get_children():
		child.queue_free()
	
	var all_items = InventoryManager.get_all_items()
	
	for item_data in all_items:
		_create_item_button(item_data)
	
	for slot in [GameConstants.SLOT_WEAPON, GameConstants.SLOT_ARMOR, GameConstants.SLOT_ACCESSORY]:
		var equipped = InventoryManager.get_equipped_item(slot)
		if equipped.size() > 0:
			_create_equipped_button(equipped, slot)

func _create_item_button(item_data: Dictionary) -> void:
	var button = Button.new()
	var item_name = item_data.get("item_name", "Unknown")
	var quantity = item_data.get("quantity", 1)
	var item_type = item_data.get("item_type", 0)
	
	button.text = "%s x%d" % [item_name, quantity]
	button.custom_minimum_size = Vector2(80, 80)
	
	if item_type == GameConstants.ITEM_TYPE_EQUIPMENT:
		button.pressed.connect(_on_equip_item.bind(item_data))
	elif item_type == GameConstants.ITEM_TYPE_CONSUMABLE:
		button.pressed.connect(_on_use_item.bind(item_data))
	
	items_grid.add_child(button)

func _create_equipped_button(item_data: Dictionary, slot: int) -> void:
	var button = Button.new()
	button.text = "[E] %s" % item_data.get("item_name", "Unknown")
	button.custom_minimum_size = Vector2(80, 80)
	button.modulate = Color(0.8, 1.0, 0.8)
	button.pressed.connect(_on_unequip_item.bind(slot))
	items_grid.add_child(button)

func _on_equip_item(item_data: Dictionary) -> void:
	InventoryManager.equip_item(item_data)
	_update_inventory_display()

func _on_unequip_item(slot: int) -> void:
	InventoryManager.unequip_item(slot)
	_update_inventory_display()

func _on_use_item(item_data: Dictionary) -> void:
	var player = Utils.get_group_node("player")
	if not player:
		return
	
	var used = false
	
	if item_data.has("heal_amount") and item_data.heal_amount > 0:
		if player.current_health < player.max_health:
			player.heal(item_data.heal_amount)
			used = true
	
	if item_data.has("restore_mana_amount") and item_data.restore_mana_amount > 0:
		if player.current_mana < player.max_mana:
			player.restore_mana(item_data.restore_mana_amount)
			used = true
	
	if used:
		var item_id = item_data.get("item_id", item_data.get("item_name", "unknown"))
		InventoryManager.remove_item_by_id(item_id, 1)
		_update_inventory_display()

func _on_save_pressed() -> void:
	App.save_game()

func _on_journal_pressed() -> void:
	journal_screen.toggle_screen()
	if journal_screen.is_open():
		GameEvents.emit_domain_event("journal_opened", {})
	else:
		GameEvents.emit_domain_event("journal_closed", {})

func _on_load_pressed() -> void:
	if App.load_game():
		_update_stats()
		_update_inventory_display()
		journal_screen.refresh()
