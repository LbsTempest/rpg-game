class_name BattleScene
extends Control

signal action_selected(action: String)
signal flee_requested()

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

var player: Node = null
var enemy: Node = null
var is_player_turn: bool = true

func _ready() -> void:
	# 连接按钮信号
	attack_button.pressed.connect(_on_attack_pressed)
	defend_button.pressed.connect(_on_defend_pressed)
	skill_button.pressed.connect(_on_skill_pressed)
	item_button.pressed.connect(_on_item_pressed)
	flee_button.pressed.connect(_on_flee_pressed)

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
	enemy.health_changed.connect(_on_enemy_health_changed)
	player.health_changed.connect(_on_player_health_changed)
	player.mana_changed.connect(_on_player_mana_changed)
	
	battle_log.text = "战斗开始！遭遇了 %s！" % enemy.enemy_name

func _on_attack_pressed() -> void:
	if is_player_turn:
		action_selected.emit("attack")

func _on_defend_pressed() -> void:
	if is_player_turn:
		action_selected.emit("defend")

func _on_skill_pressed() -> void:
	if is_player_turn:
		action_selected.emit("skill")

func _on_item_pressed() -> void:
	if is_player_turn:
		action_selected.emit("item")

func _on_flee_pressed() -> void:
	flee_requested.emit()

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

func add_log_message(message: String) -> void:
	battle_log.append_text("\n" + message)
	battle_log.scroll_to_line(battle_log.get_line_count())
