class_name NPC
extends Node2D

signal dialogue_started(npc_name: String)
signal dialogue_ended()

@export var npc_name: String = "NPC"
@export var dialogue_lines: Array[String] = ["你好，冒险者！"]
@export var can_interact: bool = true

var current_dialogue_index: int = 0
var is_dialogue_active: bool = false

@onready var interaction_area := $InteractionArea
@onready var name_label := $NameLabel

func _ready() -> void:
	if name_label:
		name_label.text = npc_name
	
	if interaction_area:
		interaction_area.body_entered.connect(_on_player_entered)

func _on_player_entered(body: Node2D) -> void:
	if body.is_in_group("player") and can_interact and not is_dialogue_active and not DialogueManager.is_active:
		DialogueManager.start_dialogue(self)

func start_dialogue() -> void:
	if dialogue_lines.is_empty():
		return
	
	is_dialogue_active = true
	current_dialogue_index = 0
	dialogue_started.emit(npc_name)
	_show_current_line()

func _show_current_line() -> void:
	if current_dialogue_index < dialogue_lines.size():
		var line := dialogue_lines[current_dialogue_index]
		print("[%s]: %s" % [npc_name, line])
		# 这里应该显示对话UI
	else:
		end_dialogue()

func next_line() -> void:
	current_dialogue_index += 1
	_show_current_line()

func end_dialogue() -> void:
	is_dialogue_active = false
	dialogue_ended.emit()
