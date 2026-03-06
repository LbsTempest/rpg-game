extends CanvasLayer

signal dialogue_started(npc_name: String)
signal dialogue_ended()
signal dialogue_line_shown(text: String, speaker: String)
signal dialogue_option_selected(option_index: int, option_text: String)

var is_active: bool = false
var current_npc: Node = null
var current_dialogue_data: Array = []
var current_index: int = 0
var is_showing_options: bool = false

@onready var dialogue_panel: PanelContainer = $DialoguePanel
@onready var speaker_label: Label = $DialoguePanel/VBoxContainer/SpeakerLabel
@onready var text_label: Label = $DialoguePanel/VBoxContainer/TextLabel
@onready var next_button: Button = $DialoguePanel/VBoxContainer/NextButton
@onready var close_button: Button = $DialoguePanel/VBoxContainer/CloseButton
@onready var options_container: VBoxContainer = $DialoguePanel/VBoxContainer/OptionsContainer

func _ready() -> void:
	dialogue_panel.visible = false
	next_button.pressed.connect(_on_next_pressed)
	close_button.pressed.connect(_on_close_pressed)
	dialogue_panel.gui_input.connect(_on_dialogue_panel_input)

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	
	if event.is_action_pressed("ui_accept"):
		if not is_showing_options:
			_on_next_pressed()
		get_viewport().set_input_as_handled()

func _on_dialogue_panel_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_showing_options:
				_on_next_pressed()

func start_dialogue(npc: Node) -> void:
	if is_active:
		return
	
	current_npc = npc
	
	if npc.has_method("get_dialogue_data"):
		current_dialogue_data = npc.get_dialogue_data()
	elif "dialogue_data" in npc:
		current_dialogue_data = npc.dialogue_data
	elif "dialogue_lines" in npc:
		current_dialogue_data = _convert_lines_to_data(npc.dialogue_lines)
	else:
		current_dialogue_data = [{"text": "...", "type": "normal"}]
	
	current_index = 0
	is_active = true
	is_showing_options = false
	
	dialogue_panel.visible = true
	_clear_options()
	_show_current_line()
	
	dialogue_started.emit(npc.npc_name)

func _convert_lines_to_data(lines: Array[String]) -> Array:
	var data: Array = []
	for line in lines:
		data.append({"text": line, "type": "normal"})
	return data

func _show_current_line() -> void:
	if current_index >= current_dialogue_data.size():
		_end_dialogue()
		return
	
	var current_data = current_dialogue_data[current_index]
	
	speaker_label.text = current_npc.npc_name
	
	if current_data.get("type", "normal") == "branch" and current_data.has("options"):
		_show_branch_options(current_data)
	else:
		text_label.text = current_data.get("text", "...")
		dialogue_line_shown.emit(text_label.text, current_npc.npc_name)
		is_showing_options = false
		_clear_options()
		
		if current_index >= current_dialogue_data.size() - 1:
			next_button.visible = false
			close_button.visible = true
		else:
			next_button.visible = true
			close_button.visible = false

func _show_branch_options(branch_data: Dictionary) -> void:
	is_showing_options = true
	text_label.text = branch_data.get("text", "Choose:")
	next_button.visible = false
	close_button.visible = false
	_clear_options()
	
	var options: Array = branch_data.get("options", [])
	for i in range(options.size()):
		var option = options[i]
		var button = Button.new()
		button.text = option.get("text", "Option " + str(i + 1))
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_option_selected.bind(i, option))
		options_container.add_child(button)

func _on_option_selected(option_index: int, option_data: Dictionary) -> void:
	dialogue_option_selected.emit(option_index, option_data.get("text", ""))
	
	if option_data.has("action"):
		var action_result = _execute_action(option_data["action"])
		if action_result:
			_end_dialogue()
			return
	
	if option_data.has("next"):
		var next_index = option_data.get("next", current_index + 1)
		if next_index < 0:
			_end_dialogue()
			return
		current_index = next_index
	else:
		current_index += 1
	
	_clear_options()
	_show_current_line()

func _execute_action(action: String) -> bool:
	if current_npc == null:
		return false
	
	match action:
		"open_shop":
			return current_npc.open_shop() if current_npc.has_method("open_shop") else false
		"accept_quest":
			return current_npc.accept_quest() if current_npc.has_method("accept_quest") else false
		"reward_quest":
			return current_npc.reward_quest() if current_npc.has_method("reward_quest") else false
	
	return false

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

func _on_next_pressed() -> void:
	if is_showing_options:
		return
	
	current_index += 1
	_show_current_line()

func _on_close_pressed() -> void:
	_end_dialogue()

func _end_dialogue() -> void:
	is_active = false
	current_npc = null
	current_dialogue_data = []
	current_index = 0
	is_showing_options = false
	
	dialogue_panel.visible = false
	_clear_options()
	
	dialogue_ended.emit()
