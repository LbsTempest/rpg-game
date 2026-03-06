class_name BattleScene
extends Control

signal action_selected(action: String, data: Dictionary)
signal flee_requested()
signal item_used(item_id: String)
signal skill_selected(skill_id: String)

@onready var enemy_name_label := $EnemyArea/EnemyContainer/EnemyNameLabel
@onready var enemy_sprite := $EnemyArea/EnemyContainer/EnemySprite
@onready var enemy_health_bar := $EnemyArea/EnemyContainer/EnemyHealthBar
@onready var enemy_hp_label := $EnemyArea/EnemyContainer/EnemyHPLabel

@onready var player_health_bar := $PlayerArea/PlayerHealthBar
@onready var player_hp_label := $PlayerArea/PlayerHPLabel
@onready var player_mp_bar := $PlayerArea/PlayerMPBar
@onready var player_mp_label := $PlayerArea/PlayerMPLabel

@onready var battle_log := $BattleLogPanel/BattleLog
@onready var turn_indicator := $TurnIndicator

@onready var attack_button := $ActionPanel/ActionVBox/AttackButton
@onready var defend_button := $ActionPanel/ActionVBox/DefendButton
@onready var skill_button := $ActionPanel/ActionVBox/SkillButton
@onready var item_button := $ActionPanel/ActionVBox/ItemButton
@onready var flee_button := $ActionPanel/ActionVBox/FleeButton

# 动态创建的技能和物品面板
var skill_panel: Panel = null
var skill_container: VBoxContainer = null
var skill_back_button: Button = null

var item_panel: Panel = null
var item_container: VBoxContainer = null
var item_back_button: Button = null

var player: Node = null
var enemy: Node = null
var is_player_turn: bool = true

func _ready() -> void:
	# 创建技能面板和物品面板
	_create_panels()
	
	# 连接按钮信号
	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	skill_button.pressed.connect(_on_skill_pressed)
	item_button.pressed.connect(_on_item_pressed)
	flee_button.pressed.connect(_on_flee_pressed)
	
	# 隐藏选择面板
	_hide_skill_panel()
	_hide_item_panel()

# 动态创建技能面板和物品面板
func _create_panels() -> void:
	# 创建技能面板
	skill_panel = Panel.new()
	skill_panel.name = "SkillPanel"
	skill_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	skill_panel.custom_minimum_size = Vector2(300, 400)
	skill_panel.visible = false
	add_child(skill_panel)
	
	var skill_vbox = VBoxContainer.new()
	skill_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	skill_panel.add_child(skill_vbox)
	
	var skill_title = Label.new()
	skill_title.text = "选择技能"
	skill_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_vbox.add_child(skill_title)
	
	var skill_scroll = ScrollContainer.new()
	skill_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skill_vbox.add_child(skill_scroll)
	
	skill_container = VBoxContainer.new()
	skill_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_scroll.add_child(skill_container)
	
	skill_back_button = Button.new()
	skill_back_button.text = "返回"
	skill_back_button.pressed.connect(_hide_skill_panel)
	skill_vbox.add_child(skill_back_button)
	
	# 创建物品面板
	item_panel = Panel.new()
	item_panel.name = "ItemPanel"
	item_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	item_panel.custom_minimum_size = Vector2(300, 400)
	item_panel.visible = false
	add_child(item_panel)
	
	var item_vbox = VBoxContainer.new()
	item_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	item_panel.add_child(item_vbox)
	
	var item_title = Label.new()
	item_title.text = "选择物品"
	item_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_vbox.add_child(item_title)
	
	var item_scroll = ScrollContainer.new()
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_vbox.add_child(item_scroll)
	
	item_container = VBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_scroll.add_child(item_container)
	
	item_back_button = Button.new()
	item_back_button.text = "返回"
	item_back_button.pressed.connect(_hide_item_panel)
	item_vbox.add_child(item_back_button)

func initialize(player_node: Node, enemy_node: Node) -> void:
	player = player_node
	enemy = enemy_node
	
	# 设置敌人显示
	var enemy_name: String = "怪物"
	var enemy_max_health: int = 50
	var enemy_current_health: int = 50
	
	if enemy:
		enemy_name = enemy.enemy_name if "enemy_name" in enemy else "怪物"
		enemy_max_health = enemy.max_health if "max_health" in enemy else 50
		enemy_current_health = enemy.current_health if "current_health" in enemy else 50
	
	enemy_name_label.text = enemy_name
	enemy_health_bar.max_value = enemy_max_health
	enemy_health_bar.value = enemy_current_health
	enemy_hp_label.text = "HP: %d/%d" % [enemy_current_health, enemy_max_health]
	
	# 设置玩家显示
	player_health_bar.max_value = player.max_health
	player_health_bar.value = player.current_health
	player_hp_label.text = "HP: %d/%d" % [player.current_health, player.max_health]
	
	player_mp_bar.max_value = player.max_mana
	player_mp_bar.value = player.current_mana
	player_mp_label.text = "MP: %d/%d" % [player.current_mana, player.max_mana]
	
	# 连接信号
	if enemy.has_signal("health_changed"):
		enemy.health_changed.connect(_on_enemy_health_changed)
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if player.has_signal("mana_changed"):
		player.mana_changed.connect(_on_player_mana_changed)
	
	battle_log.text = "战斗开始！遭遇了 %s！" % enemy_name

func _on_attack_pressed() -> void:
	if is_player_turn:
		action_selected.emit("attack", {})

func _on_defend_pressed() -> void:
	if is_player_turn:
		action_selected.emit("defend", {})

func _on_skill_pressed() -> void:
	if is_player_turn:
		_show_skill_panel()

func _on_item_pressed() -> void:
	if is_player_turn:
		_show_item_panel()

func _on_flee_pressed() -> void:
	flee_requested.emit()

# 显示技能选择面板
func _show_skill_panel() -> void:
	_update_skill_buttons()
	skill_panel.visible = true
	item_panel.visible = false

# 隐藏技能选择面板
func _hide_skill_panel() -> void:
	if skill_panel:
		skill_panel.visible = false

# 更新技能按钮
func _update_skill_buttons() -> void:
	if not skill_container:
		return
	
	# 清除旧按钮
	for child in skill_container.get_children():
		child.queue_free()
	
	# 获取可用技能
	var skills = SkillManager.get_available_skills_for_ui(player)
	
	if skills.is_empty():
		var label = Label.new()
		label.text = "没有可用的技能"
		skill_container.add_child(label)
		return
	
	# 创建技能按钮
	for skill in skills:
		var button = Button.new()
		var skill_name = skill.get("name", "未知技能")
		var mana_cost = skill.get("mana_cost", 0)
		var cooldown = skill.get("current_cooldown", 0)
		var can_use = skill.get("can_use", false)
		
		var button_text = "%s (%d MP)" % [skill_name, mana_cost]
		if cooldown > 0:
			button_text += " [冷却%d]" % cooldown
		elif not can_use:
			button_text += " [不可用]"
		
		button.text = button_text
		button.disabled = not can_use
		button.tooltip_text = skill.get("description", "") + "\n" + skill.get("reason", "")
		
		# 使用闭包绑定技能ID
		var skill_id = skill.get("skill_id", "")
		button.pressed.connect(func(): _on_skill_chosen(skill_id))
		
		skill_container.add_child(button)

# 技能被选择
func _on_skill_chosen(skill_id: String) -> void:
	_hide_skill_panel()
	skill_selected.emit(skill_id)

# 显示物品选择面板
func _show_item_panel() -> void:
	_update_item_buttons()
	item_panel.visible = true
	skill_panel.visible = false

# 隐藏物品选择面板
func _hide_item_panel() -> void:
	if item_panel:
		item_panel.visible = false

# 更新物品按钮
func _update_item_buttons() -> void:
	if not item_container:
		return
	
	# 清除旧按钮
	for child in item_container.get_children():
		child.queue_free()
	
	# 获取消耗品列表
	var consumables = _get_consumable_items()
	
	if consumables.is_empty():
		var label = Label.new()
		label.text = "没有可用的消耗品"
		item_container.add_child(label)
		return
	
	# 创建物品按钮
	for item in consumables:
		var button = Button.new()
		var item_name = item.get("item_name", "未知物品")
		var quantity = item.get("quantity", 0)
		var desc = item.get("description", "")
		
		button.text = "%s x%d" % [item_name, quantity]
		button.tooltip_text = desc
		
		# 使用闭包绑定物品ID
		var item_id = item.get("item_id", "")
		button.pressed.connect(func(): _on_item_chosen(item_id))
		
		item_container.add_child(button)

# 获取可使用的消耗品
func _get_consumable_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var all_items = InventoryManager.get_all_items()
	
	for item in all_items:
		# 只显示消耗品
		if item.get("item_type", 0) == 0:  # CONSUMABLE
			result.append(item)
	
	return result

# 物品被选择
func _on_item_chosen(item_id: String) -> void:
	_hide_item_panel()
	item_used.emit(item_id)

func _on_enemy_health_changed(current: int, maximum: int) -> void:
	enemy_health_bar.value = current
	enemy_hp_label.text = "HP: %d/%d" % [current, maximum]

func _on_player_health_changed(current: int, maximum: int) -> void:
	player_health_bar.value = current
	player_hp_label.text = "HP: %d/%d" % [current, maximum]

func _on_player_mana_changed(current: int, maximum: int) -> void:
	player_mp_bar.value = current
	player_mp_label.text = "MP: %d/%d" % [current, maximum]

func set_turn(player_turn: bool) -> void:
	is_player_turn = player_turn
	turn_indicator.text = "玩家回合" if player_turn else "敌人回合"
	
	# 禁用/启用按钮
	attack_button.disabled = not player_turn
	defend_button.disabled = not player_turn
	skill_button.disabled = not player_turn
	item_button.disabled = not player_turn
	flee_button.disabled = not player_turn
	
	# 如果不在玩家回合，隐藏面板
	if not player_turn:
		_hide_skill_panel()
		_hide_item_panel()

func add_log_message(message: String) -> void:
	battle_log.append_text("\n" + message)
	battle_log.scroll_to_line(battle_log.get_line_count())
