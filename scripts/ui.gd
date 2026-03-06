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
@onready var load_button := $ButtonsHBox/LoadButton

@onready var inventory_panel := $InventoryPanel
@onready var items_grid := $InventoryPanel/InventoryVBox/ItemsScroll/ItemsGrid
@onready var close_button := $InventoryPanel/InventoryVBox/CloseButton

var player: Node
var is_inventory_open: bool = false

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.mana_changed.connect(_on_mana_changed)
		player.level_up.connect(_on_level_up)
		_update_stats()
	
	InventoryManager.item_added.connect(_on_inventory_changed)
	InventoryManager.item_removed.connect(_on_inventory_changed)
	InventoryManager.equipment_changed.connect(_on_equipment_changed)
	
	inventory_button.pressed.connect(_on_inventory_pressed)
	save_button.pressed.connect(_on_save_pressed)
	load_button.pressed.connect(_on_load_pressed)
	close_button.pressed.connect(_on_close_inventory)
	
	_add_default_items()
	_update_inventory_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("open_inventory"):
		_on_inventory_pressed()
	if event.is_action_pressed("ui_focus_next"):
		if Input.is_action_pressed("ui_accept"):
			GameManager.save_game()
	if event.is_action_pressed("ui_cancel"):
		if is_inventory_open:
			_close_inventory()

func _update_stats() -> void:
	if not player:
		return
	
	hp_bar.max_value = player.max_health
	hp_bar.value = player.current_health
	hp_label.text = "HP: %d/%d" % [player.current_health, player.max_health]
	
	mp_bar.max_value = player.max_mana
	mp_bar.value = player.current_mana
	mp_label.text = "MP: %d/%d" % [player.current_mana, player.max_mana]
	
	exp_label.text = "EXP: %d/%d" % [player.experience, player.experience_to_next_level]
	level_label.text = "Lv.%d" % player.level
	
	gold_label.text = "Gold: %d" % InventoryManager.gold
	
	var base_attack: int = player.attack
	var equip_attack: int = InventoryManager.get_total_attack()
	var total_attack: int = base_attack + equip_attack
	if equip_attack > 0:
		attack_label.text = "ATK: %d (+%d)" % [total_attack, equip_attack]
	else:
		attack_label.text = "ATK: %d" % total_attack
	
	var base_defense: int = player.defense
	var equip_defense: int = InventoryManager.get_total_defense()
	var total_defense: int = base_defense + equip_defense
	if equip_defense > 0:
		defense_label.text = "DEF: %d (+%d)" % [total_defense, equip_defense]
	else:
		defense_label.text = "DEF: %d" % total_defense

func _on_health_changed(current: int, maximum: int) -> void:
	hp_bar.max_value = maximum
	hp_bar.value = current
	hp_label.text = "HP: %d/%d" % [current, maximum]

func _on_mana_changed(current: int, maximum: int) -> void:
	mp_bar.max_value = maximum
	mp_bar.value = current
	mp_label.text = "MP: %d/%d" % [current, maximum]

func _on_level_up(new_level: int) -> void:
	level_label.text = "Lv.%d" % new_level
	exp_label.text = "EXP: %d/%d" % [player.experience, player.experience_to_next_level]

func _on_inventory_changed(_item_id: String, _amount: int) -> void:
	_update_inventory_display()
	_update_stats()

func _on_equipment_changed(_slot: String, _item: Dictionary) -> void:
	_update_stats()

func _on_inventory_pressed() -> void:
	if is_inventory_open:
		_close_inventory()
	else:
		_open_inventory()

func _open_inventory() -> void:
	is_inventory_open = true
	GameManager.is_inventory_open = true
	inventory_panel.visible = true
	# 等待一帧确保容器布局完成
	await get_tree().process_frame
	_update_inventory_display()

func _close_inventory() -> void:
	is_inventory_open = false
	GameManager.is_inventory_open = false
	inventory_panel.visible = false

func _on_close_inventory() -> void:
	_close_inventory()

func _update_inventory_display() -> void:
	for child in items_grid.get_children():
		child.queue_free()
	
	# 使用新的物品系统获取所有物品（已堆叠）
	var all_items: Array[Dictionary] = InventoryManager.get_all_items()
	
	for item_data in all_items:
		if item_data and item_data is Dictionary:
			var button := Button.new()
			var item_name: String = item_data.get("item_name", "Unknown")
			var quantity: int = item_data.get("quantity", 1)
			
			# 显示名称和数量
			if quantity > 1:
				button.text = "%s\nx%d" % [item_name, quantity]
			else:
				button.text = item_name
			
			button.custom_minimum_size = Vector2(90, 70)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			# 创建物品字典的副本用于点击处理
			var item_copy: Dictionary = item_data.duplicate()
			item_copy.erase("quantity")
			item_copy.erase("item_id")
			
			button.pressed.connect(_on_item_clicked.bind(item_copy))
			items_grid.add_child(button)

func _on_item_clicked(item: Dictionary) -> void:
	var item_name: String = item.get("item_name", "Unknown")
	print("Clicked: ", item_name)
	
	var item_type: int = item.get("item_type", 0)
	
	if item_type == 0:
		var heal_amount: int = item.get("heal_amount", 0)
		var restore_mana: int = item.get("restore_mana_amount", 0)
		
		if heal_amount > 0 and player:
			player.heal(heal_amount)
			InventoryManager.remove_item(item, 1)
			print("Used ", item_name, " healed ", heal_amount, " HP")
		
		if restore_mana > 0 and player:
			player.restore_mana(restore_mana)
			InventoryManager.remove_item(item, 1)
			print("Used ", item_name, " restored ", restore_mana, " MP")
			
		_update_stats()
		_update_inventory_display()
		
	elif item_type == 1:
		InventoryManager.equip_item(item)
		print("Equipped: ", item_name)
		_update_inventory_display()

func _on_save_pressed() -> void:
	GameManager.save_game()

func _on_load_pressed() -> void:
	GameManager.load_game()
	_update_stats()
	_update_inventory_display()

func _add_default_items() -> void:
	var potion := _create_item("生命药水", "恢复50点生命", 0, 50, 0)
	var mana_potion := _create_item("魔法药水", "恢复30点魔法", 0, 0, 30)
	var sword := _create_item("铁剑", "攻击力+10", 1, 10, 0)
	var armor := _create_item("皮甲", "防御力+5", 1, 0, 0)
	
	InventoryManager.add_item(potion, 3)
	InventoryManager.add_item(mana_potion, 2)
	InventoryManager.add_item(sword, 1)
	InventoryManager.add_item(armor, 1)
	InventoryManager.gold = 100

func _create_item(name: String, desc: String, type: int, heal: int, mana: int) -> Dictionary:
	return {
		"item_name": name,
		"description": desc,
		"item_type": type,
		"heal_amount": heal,
		"restore_mana_amount": mana,
		"attack": 10 if "剑" in name else 0,
		"defense": 5 if "甲" in name else 0,
		"equipment_slot": 1 if "剑" in name else (2 if "甲" in name else 0),
		"price": 50
	}
