extends CanvasLayer

signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal dialogue_line_shown(text: String, speaker: String)

var is_active: bool = false
var current_npc: Node = null
var current_lines: Array[String] = []
var current_index: int = 0

@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $DialoguePanel/VBoxContainer/TextLabel
@onready var next_button: Button = $DialoguePanel/VBoxContainer/NextButton
@onready var close_button: Button = $DialoguePanel/VBoxContainer/CloseButton

func _ready() -> void:
	dialogue_panel.visible = false
	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_pressed)

func _input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("ui_accept"):
		_on_next_pressed()

func start_dialogue(npc: Node) -> void:
	if is_active:
		return
	
	current_npc = npc
	current_lines = npc.dialogue_lines if "dialogue_lines" in npc else ["..."]
	current_index = 0
	is_active = true
	
	dialogue_panel.visible = true
	_show_current_line()
	
	var npc_name: String = npc.npc_name if "npc_name" in npc else "NPC"
	dialogue_started.emit(npc_name)

func _show_current_line() -> void:
	if current_index < current_lines.size():
		var line: String = current_lines[current_index]
		var npc_name: String = current_npc.npc_name if "npc_name" in current_npc else "NPC"
		
		speaker_label.text = npc_name
		text_label.text = line
		dialogue_line_shown.emit(line, npc_name)
		
		# 如果是对话的最后一句，隐藏"下一句"按钮，显示"关闭"按钮
		if current_index >= current_lines.size() - 1:
			next_button.visible = false
			close_button.visible = true
		else:
			next_button.visible = true
			close_button.visible = false
	else:
		_end_dialogue()

func _on_next_pressed() -> void:
	current_index += 1
	_show_current_line()

func _on_close_pressed() -> void:
	_end_dialogue()

func _end_dialogue() -> void:
	is_active = false
	dialogue_panel.visible = false
	current_npc = null
	dialogue_ended.emit()
