class_name DialogueScreen
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
var _active_story_segment_id: String = ""
var _dialogue_presenter := DialoguePresenter.new()

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

	var story_dialogue_data: Array = _build_story_dialogue_for_npc(npc)
	if not story_dialogue_data.is_empty():
		current_dialogue_data = story_dialogue_data
	elif npc.has_method("get_dialogue_data"):
		current_dialogue_data = npc.get_dialogue_data()
	elif "dialogue_data" in npc:
		current_dialogue_data = npc.dialogue_data
	elif "dialogue_lines" in npc:
		current_dialogue_data = _convert_lines_to_data(npc.dialogue_lines)
	else:
		current_dialogue_data = [{"text": "...", "type": "normal"}]
	
	if current_dialogue_data.is_empty():
		current_dialogue_data = [{"text": "...", "type": "normal"}]

	current_index = 0
	is_active = true
	is_showing_options = false
	
	dialogue_panel.visible = true
	UIRouter.register_modal("dialogue", Callable(self, "_end_dialogue"), 60, true)
	_clear_options()
	_show_current_line()
	
	var npc_display_name: String = npc.npc_name if "npc_name" in npc else String(npc.name)
	dialogue_started.emit(npc_display_name)

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
	
	var fallback_speaker: String = current_npc.npc_name if "npc_name" in current_npc else String(current_npc.name)
	speaker_label.text = current_data.get("speaker", fallback_speaker)
	
	if current_data.get("type", "normal") == "branch" and current_data.has("options"):
		_show_branch_options(current_data)
	else:
		text_label.text = current_data.get("text", "...")
		dialogue_line_shown.emit(text_label.text, speaker_label.text)
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
		var action_id: String = String(option_data.get("action", ""))
		var action_result = _execute_action(option_data)
		if action_result:
			if action_id == "choose_story_branch" and _refresh_story_dialogue():
				return
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

func _execute_action(option_data: Dictionary) -> bool:
	if current_npc == null:
		return false

	var context := {
		"source": "dialogue",
		"npc": current_npc,
		"dialogue_index": current_index
	}
	var result: Dictionary = TriggerRouter.execute_dialogue_option(option_data, context)
	return result.get("success", false)

func _clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()

func _on_next_pressed() -> void:
	if is_showing_options:
		return
	
	if not _active_story_segment_id.is_empty():
		StoryService.advance_story()

	current_index += 1
	_show_current_line()

func _on_close_pressed() -> void:
	if not _active_story_segment_id.is_empty():
		StoryService.advance_story()
	_end_dialogue()

func _end_dialogue() -> void:
	is_active = false
	current_npc = null
	current_dialogue_data = []
	current_index = 0
	is_showing_options = false
	_active_story_segment_id = ""
	
	dialogue_panel.visible = false
	UIRouter.unregister_modal("dialogue")
	_clear_options()
	
	dialogue_ended.emit()

func _build_story_dialogue_for_npc(npc: Node) -> Array:
	var segment_id: String = _extract_story_segment_id(npc)
	if segment_id.is_empty():
		_active_story_segment_id = ""
		return []

	if StoryService.get_current_segment_id() != segment_id:
		var start_result: Dictionary = StoryService.start_story_segment(segment_id)
		if not start_result.get("success", false):
			push_warning("Failed to start story segment: %s" % segment_id)
			_active_story_segment_id = ""
			return []

	var segment_definition: Dictionary = StoryService.get_current_segment_definition()
	if segment_definition.is_empty():
		_active_story_segment_id = ""
		return []

	_active_story_segment_id = StoryService.get_current_segment_id()
	return _dialogue_presenter.build_story_dialogue(segment_definition, StoryService.get_current_step_index())

func _extract_story_segment_id(npc: Node) -> String:
	if npc == null:
		return ""
	if npc.has_method("get_story_segment_id"):
		return String(npc.get_story_segment_id())
	if "story_segment_id" in npc:
		return String(npc.story_segment_id)
	return ""

func _refresh_story_dialogue() -> bool:
	if _active_story_segment_id.is_empty() or not StoryService.is_story_active():
		return false

	var segment_definition: Dictionary = StoryService.get_current_segment_definition()
	if segment_definition.is_empty():
		return false

	var refreshed_dialogue: Array = _dialogue_presenter.build_story_dialogue(
		segment_definition,
		StoryService.get_current_step_index()
	)
	if refreshed_dialogue.is_empty():
		return false

	current_dialogue_data = refreshed_dialogue
	current_index = 0
	is_showing_options = false
	_clear_options()
	_show_current_line()
	return true

