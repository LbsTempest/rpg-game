class_name BattleScreen
extends Control

signal action_selected(action: String, data: Dictionary)
signal flee_requested()
signal item_used(item_id: String)
signal skill_selected(skill_id: String)

@onready var enemy_name_label := $EnemyArea/EnemyContainer/EnemyNameLabel
@onready var enemy_sprite := $EnemyArea/EnemyContainer/EnemySprite
@onready var enemy_health_bar := $EnemyArea/EnemyContainer/EnemyHealthBar
@onready var enemy_hp_label := $EnemyArea/EnemyContainer/EnemyHPLabel

@onready var player_name_label := $PlayerArea/PlayerNameLabel
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

var skill_panel: Panel = null
var skill_container: VBoxContainer = null
var skill_back_button: Button = null

var item_panel: Panel = null
var item_container: VBoxContainer = null
var item_back_button: Button = null

var is_player_turn: bool = true
var _battle_view: Dictionary = {}

func _ready() -> void:
	_create_panels()

	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	skill_button.pressed.connect(_on_skill_pressed)
	item_button.pressed.connect(_on_item_pressed)
	flee_button.pressed.connect(_on_flee_pressed)

	_hide_skill_panel()
	_hide_item_panel()

func initialize(view_data: Dictionary) -> void:
	if not BattleService.battle_state_changed.is_connected(_on_battle_state_changed):
		BattleService.battle_state_changed.connect(_on_battle_state_changed)
	_on_battle_state_changed(view_data)

func _create_panels() -> void:
	skill_panel = Panel.new()
	skill_panel.name = "SkillPanel"
	skill_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	skill_panel.custom_minimum_size = Vector2(300, 400)
	skill_panel.visible = false
	add_child(skill_panel)

	var skill_vbox := VBoxContainer.new()
	skill_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	skill_panel.add_child(skill_vbox)

	var skill_title := Label.new()
	skill_title.text = "选择技能"
	skill_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skill_vbox.add_child(skill_title)

	var skill_scroll := ScrollContainer.new()
	skill_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	skill_vbox.add_child(skill_scroll)

	skill_container = VBoxContainer.new()
	skill_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skill_scroll.add_child(skill_container)

	skill_back_button = Button.new()
	skill_back_button.text = "返回"
	skill_back_button.pressed.connect(_hide_skill_panel)
	skill_vbox.add_child(skill_back_button)

	item_panel = Panel.new()
	item_panel.name = "ItemPanel"
	item_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE, 0)
	item_panel.custom_minimum_size = Vector2(300, 400)
	item_panel.visible = false
	add_child(item_panel)

	var item_vbox := VBoxContainer.new()
	item_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 10)
	item_panel.add_child(item_vbox)

	var item_title := Label.new()
	item_title.text = "选择物品"
	item_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_vbox.add_child(item_title)

	var item_scroll := ScrollContainer.new()
	item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	item_vbox.add_child(item_scroll)

	item_container = VBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_scroll.add_child(item_container)

	item_back_button = Button.new()
	item_back_button.text = "返回"
	item_back_button.pressed.connect(_hide_item_panel)
	item_vbox.add_child(item_back_button)

func _on_attack_pressed() -> void:
	if is_player_turn:
		action_selected.emit("attack", {"target_type": "enemy_single"})

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

func _show_skill_panel() -> void:
	_update_skill_buttons()
	skill_panel.visible = true
	item_panel.visible = false

func _hide_skill_panel() -> void:
	if skill_panel:
		skill_panel.visible = false

func _update_skill_buttons() -> void:
	if not skill_container:
		return

	for child in skill_container.get_children():
		child.queue_free()

	var actor_id: String = _battle_view.get("active_player_id", "")
	var skills: Array[Dictionary] = BattleService.get_available_skills_for_ui(actor_id)
	if skills.is_empty():
		var label := Label.new()
		label.text = "没有可用的技能"
		skill_container.add_child(label)
		return

	for skill in skills:
		var button := Button.new()
		var skill_name: String = skill.get("name", "未知技能")
		var mana_cost: int = skill.get("mana_cost", 0)
		var cooldown: int = skill.get("current_cooldown", 0)
		var can_use: bool = skill.get("can_use", false)

		var button_text := "%s (%d 魔法)" % [skill_name, mana_cost]
		if cooldown > 0:
			button_text += " [冷却%d]" % cooldown
		elif not can_use:
			button_text += " [不可用]"

		button.text = button_text
		button.disabled = not can_use
		button.tooltip_text = skill.get("description", "") + "\n" + skill.get("reason", "")

		var skill_id: String = skill.get("skill_id", "")
		button.pressed.connect(func(): _on_skill_chosen(skill_id))

		skill_container.add_child(button)

func _on_skill_chosen(skill_id: String) -> void:
	_hide_skill_panel()
	skill_selected.emit(skill_id)

func _show_item_panel() -> void:
	_update_item_buttons()
	item_panel.visible = true
	skill_panel.visible = false

func _hide_item_panel() -> void:
	if item_panel:
		item_panel.visible = false

func _update_item_buttons() -> void:
	if not item_container:
		return

	for child in item_container.get_children():
		child.queue_free()

	var consumables: Array[Dictionary] = BattleService.get_consumable_items_for_ui(
		_battle_view.get("active_player_id", "")
	)
	if consumables.is_empty():
		var label := Label.new()
		label.text = "没有可用的消耗品"
		item_container.add_child(label)
		return

	for item in consumables:
		var button := Button.new()
		var item_name: String = item.get("display_name", item.get("item_name", "未知物品"))
		var quantity: int = item.get("quantity", 0)
		var desc: String = item.get("description", "")

		button.text = "%s x%d" % [item_name, quantity]
		button.tooltip_text = desc

		var item_id: String = item.get("item_id", "")
		button.pressed.connect(func(): _on_item_chosen(item_id))

		item_container.add_child(button)

func _on_item_chosen(item_id: String) -> void:
	_hide_item_panel()
	item_used.emit(item_id)

func set_turn(player_turn: bool) -> void:
	is_player_turn = player_turn
	turn_indicator.text = "玩家回合" if player_turn else "敌人回合"

	attack_button.disabled = not player_turn
	defend_button.disabled = not player_turn
	skill_button.disabled = not player_turn
	item_button.disabled = not player_turn
	flee_button.disabled = not player_turn

	if not player_turn:
		_hide_skill_panel()
		_hide_item_panel()

func add_log_message(message: String) -> void:
	battle_log.append_text("\n" + message)
	battle_log.scroll_to_line(battle_log.get_line_count())

func _on_battle_state_changed(view_data: Dictionary) -> void:
	_battle_view = view_data.duplicate(true)

	var active_enemy: Dictionary = _find_combatant(
		_battle_view.get("enemy_team", []),
		_battle_view.get("active_enemy_id", "")
	)
	var active_player: Dictionary = _find_combatant(
		_battle_view.get("player_team", []),
		_battle_view.get("active_player_id", "")
	)

	_render_enemy(active_enemy)
	_render_player(active_player)

	var log_lines: PackedStringArray = _battle_view.get("logs", PackedStringArray())
	battle_log.text = "\n".join(log_lines)
	battle_log.scroll_to_line(max(battle_log.get_line_count() - 1, 0))

	set_turn(_battle_view.get("player_turn", true))

	if skill_panel and skill_panel.visible:
		_update_skill_buttons()
	if item_panel and item_panel.visible:
		_update_item_buttons()

func _render_enemy(enemy_data: Dictionary) -> void:
	if enemy_data.is_empty():
		enemy_name_label.text = "怪物"
		enemy_health_bar.max_value = 1
		enemy_health_bar.value = 0
		enemy_hp_label.text = "HP: 0/0"
		enemy_sprite.visible = false
		return

	var max_health: int = max(1, enemy_data.get("max_health", 1))
	var current_health: int = max(0, enemy_data.get("current_health", 0))
	enemy_name_label.text = enemy_data.get("display_name", "怪物")
	enemy_health_bar.max_value = max_health
	enemy_health_bar.value = current_health
	enemy_hp_label.text = "HP: %d/%d" % [current_health, max_health]
	enemy_sprite.visible = true

func _render_player(player_data: Dictionary) -> void:
	if player_data.is_empty():
		player_name_label.text = "Hero"
		player_health_bar.max_value = 1
		player_health_bar.value = 0
		player_hp_label.text = "HP: 0/0"
		player_mp_bar.max_value = 1
		player_mp_bar.value = 0
		player_mp_label.text = "MP: 0/0"
		return

	var max_health: int = max(1, player_data.get("max_health", 1))
	var current_health: int = max(0, player_data.get("current_health", 0))
	var max_mana: int = max(1, player_data.get("max_mana", 1))
	var current_mana: int = max(0, player_data.get("current_mana", 0))

	player_name_label.text = player_data.get("display_name", "Hero")
	player_health_bar.max_value = max_health
	player_health_bar.value = current_health
	player_hp_label.text = "HP: %d/%d" % [current_health, max_health]
	player_mp_bar.max_value = max_mana
	player_mp_bar.value = current_mana
	player_mp_label.text = "MP: %d/%d" % [current_mana, max_mana]

func _find_combatant(team: Array, combatant_id: String) -> Dictionary:
	for combatant in team:
		if combatant is Dictionary and combatant.get("combatant_id", "") == combatant_id:
			return combatant

	for combatant in team:
		if combatant is Dictionary and combatant.get("is_alive", false):
			return combatant

	return {}

