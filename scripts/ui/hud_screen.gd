class_name HUDScreen
extends CanvasLayer

@onready var hp_bar: ProgressBar = $StatsPanel/VBox/HPBar
@onready var hp_label: Label = $StatsPanel/VBox/HPLabel
@onready var mp_bar: ProgressBar = $StatsPanel/VBox/MPBar
@onready var mp_label: Label = $StatsPanel/VBox/MPLabel
@onready var exp_label: Label = $StatsPanel/VBox/EXPLabel
@onready var level_label: Label = $StatsPanel/VBox/LevelLabel
@onready var gold_label: Label = $StatsPanel/VBox/GoldLabel
@onready var attack_label: Label = $StatsPanel/VBox/AttackLabel
@onready var defense_label: Label = $StatsPanel/VBox/DefenseLabel

@onready var inventory_button: Button = $ButtonsHBox/InventoryButton
@onready var save_button: Button = $ButtonsHBox/SaveButton
@onready var journal_button: Button = $ButtonsHBox/JournalButton
@onready var load_button: Button = $ButtonsHBox/LoadButton

@onready var inventory_screen: InventoryScreen = $InventoryPanel
@onready var journal_screen: JournalScreen = $JournalScreen

var player: Node = null

func _ready() -> void:
	_bind_player()
	_connect_inventory_signals()
	_connect_ui_signals()

	App.game_loaded.connect(_on_game_loaded)
	inventory_screen.refresh()
	_update_stats()

func _bind_player() -> void:
	player = Utils.get_group_node("player")
	inventory_screen.set_player(player)
	if player == null:
		return

	if not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	if not player.mana_changed.is_connected(_on_mana_changed):
		player.mana_changed.connect(_on_mana_changed)
	if not player.level_up.is_connected(_on_level_up):
		player.level_up.connect(_on_level_up)

func _connect_inventory_signals() -> void:
	if not InventoryService.item_added.is_connected(_on_inventory_changed):
		InventoryService.item_added.connect(_on_inventory_changed)
	if not InventoryService.item_removed.is_connected(_on_inventory_changed):
		InventoryService.item_removed.connect(_on_inventory_changed)
	if not InventoryService.equipment_changed.is_connected(_on_equipment_changed):
		InventoryService.equipment_changed.connect(_on_equipment_changed)
	if not InventoryService.gold_changed.is_connected(_on_gold_changed):
		InventoryService.gold_changed.connect(_on_gold_changed)

func _connect_ui_signals() -> void:
	inventory_button.pressed.connect(_on_inventory_pressed)
	save_button.pressed.connect(_on_save_pressed)
	journal_button.pressed.connect(_on_journal_pressed)
	load_button.pressed.connect(_on_load_pressed)

func _update_stats() -> void:
	if player == null:
		_bind_player()
		if player == null:
			return

	hp_bar.max_value = player.max_health
	hp_bar.value = player.current_health
	hp_label.text = Utils.format_health(player.current_health, player.max_health)

	mp_bar.max_value = player.max_mana
	mp_bar.value = player.current_mana
	mp_label.text = Utils.format_mana(player.current_mana, player.max_mana)

	exp_label.text = "经验: %d/%d" % [player.experience, player.experience_to_next_level]
	level_label.text = "等级:%d" % player.level
	gold_label.text = Utils.format_gold(InventoryService.gold)

	var base_attack: int = player.attack
	var equip_attack: int = InventoryService.get_total_attack()
	var total_attack: int = base_attack + equip_attack
	if equip_attack > 0:
		attack_label.text = "攻击: %d (+%d)" % [total_attack, equip_attack]
	else:
		attack_label.text = "攻击: %d" % total_attack

	var base_defense: int = player.defense
	var equip_defense: int = InventoryService.get_total_defense()
	var total_defense: int = base_defense + equip_defense
	if equip_defense > 0:
		defense_label.text = "防御: %d (+%d)" % [total_defense, equip_defense]
	else:
		defense_label.text = "防御: %d" % total_defense

func _on_health_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = Utils.format_health(current, maximum)

func _on_mana_changed(current: int, maximum: int) -> void:
	mp_bar.max_value = maximum
	mp_bar.value = current
	mp_label.text = Utils.format_mana(current, maximum)

func _on_level_up(new_level: int) -> void:
	level_label.text = "等级:%d" % new_level
	exp_label.text = "经验: %d/%d" % [player.experience, player.experience_to_next_level]

func _on_inventory_changed(_item_id: String, _amount: int) -> void:
	inventory_screen.refresh()
	_update_stats()

func _on_equipment_changed(_slot: String, _item: Dictionary) -> void:
	inventory_screen.refresh()
	_update_stats()

func _on_gold_changed(new_amount: int) -> void:
	gold_label.text = Utils.format_gold(new_amount)

func _on_inventory_pressed() -> void:
	inventory_screen.toggle_screen()

func toggle_inventory_from_router() -> void:
	_on_inventory_pressed()

func _on_save_pressed() -> void:
	App.save_game()

func _on_journal_pressed() -> void:
	journal_screen.toggle_screen()
	if journal_screen.is_open():
		GameEvents.emit_domain_event("journal_opened", {})
	else:
		GameEvents.emit_domain_event("journal_closed", {})

func _on_load_pressed() -> void:
	App.load_game()

func _on_game_loaded() -> void:
	_bind_player()
	inventory_screen.refresh()
	journal_screen.refresh()
	_update_stats()

func show_screen() -> void:
	visible = true

func hide_screen() -> void:
	visible = false
