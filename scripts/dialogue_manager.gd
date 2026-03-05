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
	
	# 点击对话框区域也可以推进（除了按钮）
	dialogue_panel.gui_input.connect(_on_dialogue_panel_input)

func _input(event: InputEvent) -> void:
	if not is_active:
		return
	
	# 键盘/手柄确认键
	if event.is_action_pressed("ui_accept"):
		if not is_showing_options:
			_on_next_pressed()
		get_viewport().set_input_as_handled()
	
	# 鼠标点击（左键）
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# 检查是否点击在选项按钮上（如果是，让按钮自己处理）
			if not _is_mouse_over_options():
				if not is_showing_options:
					_on_next_pressed()
				get_viewport().set_input_as_handled()

func _is_mouse_over_options() -> bool:
	# 检查鼠标是否在选项按钮上
	for child in options_container.get_children():
		if child is Button and child.get_global_rect().has_point(get_viewport().get_mouse_position()):
			return true
	return false

func _on_dialogue_panel_input(event: InputEvent) -> void:
	# 处理对话框面板的输入事件
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if not is_showing_options and not _is_mouse_over_button():
				_on_next_pressed()

func _is_mouse_over_button() -> bool:
	# 检查是否在按钮上
	return next_button.get_global_rect().has_point(get_viewport().get_mouse_position()) or \
		   close_button.get_global_rect().has_point(get_viewport().get_mouse_position())

func start_dialogue(npc: Node) -> void:
	if is_active:
		return
	
	current_npc = npc
	
	# 获取对话数据（支持新的分支格式或旧的简单格式）
	if npc.has_method("get_dialogue_data"):
		current_dialogue_data = npc.get_dialogue_data()
	elif "dialogue_data" in npc:
		current_dialogue_data = npc.dialogue_data
	elif "dialogue_lines" in npc:
		# 转换为新格式
		current_dialogue_data = _convert_lines_to_data(npc.dialogue_lines)
	else:
		current_dialogue_data = [{"text": "...", "type": "normal"}]
	
	current_index = 0
	is_active = true
	is_showing_options = false
	
	dialogue_panel.visible = true
	_clear_options()
	_show_current_line()
	
	var npc_name: String = npc.npc_name if "npc_name" in npc else "NPC"
	dialogue_started.emit(npc_name)

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
	var npc_name: String = current_npc.npc_name if "npc_name" in current_npc else "NPC"
	
	speaker_label.text = npc_name
	
	# 检查是否是分支
	if current_data.get("type", "normal") == "branch" and current_data.has("options"):
		_show_branch_options(current_data)
	else:
		# 普通对话行
		text_label.text = current_data.get("text", "...")
		dialogue_line_shown.emit(text_label.text, npc_name)
		is_showing_options = false
		_clear_options()
		
		# 检查是否是最后一句
		if current_index >= current_dialogue_data.size() - 1:
			next_button.visible = false
			close_button.visible = true
		else:
			next_button.visible = true
			close_button.visible = false

func _show_branch_options(branch_data: Dictionary) -> void:
	is_showing_options = true
	text_label.text = branch_data.get("text", "请选择：")
	next_button.visible = false
	close_button.visible = false
	_clear_options()
	
	var options: Array = branch_data.get("options", [])
	for i in range(options.size()):
		var option = options[i]
		var button := Button.new()
		button.text = option.get("text", "选项 " + str(i + 1))
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(_on_option_selected.bind(i, option))
		options_container.add_child(button)

func _on_option_selected(option_index: int, option_data: Dictionary) -> void:
	dialogue_option_selected.emit(option_index, option_data.get("text", ""))
	
	# 如果选项有跳转目标，跳转到指定行
	if option_data.has("next"):
		current_index = option_data.get("next", current_index + 1)
	else:
		current_index += 1
	
	_clear_options()
	_show_current_line()

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

func _on_next_pressed() -> void:
	if is_showing_options:
		return  # 有选项时必须选择才能继续
	
	current_index += 1
	_show_current_line()

func _on_close_pressed() -> void:
	_end_dialogue()

func _end_dialogue() -> void:
	is_active = false
	is_showing_options = false
	dialogue_panel.visible = false
	_clear_options()
	current_npc = null
	dialogue_ended.emit()

# 公共方法：用于脚本控制对话
func jump_to_line(line_index: int) -> void:
	if line_index >= 0 and line_index < current_dialogue_data.size():
		current_index = line_index
		_show_current_line()

func set_dialogue_data(data: Array) -> void:
	current_dialogue_data = data
	current_index = 0
	_clear_options()
	_show_current_line()
