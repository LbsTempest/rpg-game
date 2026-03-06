extends Control

signal new_game_started
signal load_game_requested
signal game_exited

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var new_game_button: Button = $VBoxContainer/NewGameButton
@onready var load_game_button: Button = $VBoxContainer/LoadGameButton
@onready var exit_button: Button = $VBoxContainer/ExitButton
@onready var version_label: Label = $VersionLabel

func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	if not GameManager.has_save_file():
		load_game_button.disabled = true
		load_game_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	version_label.text = "v1.0"
	new_game_button.grab_focus()

func _on_new_game_pressed() -> void:
	GameManager.start_new_game()
	new_game_started.emit()

func _on_load_game_pressed() -> void:
	if GameManager.load_game():
		load_game_requested.emit()
		get_tree().change_scene_to_file(GameConstants.SCENE_MAIN)
	else:
		_show_error_dialog("加载失败", "无法读取存档文件。")

func _on_exit_pressed() -> void:
	game_exited.emit()
	get_tree().quit()

func _show_error_dialog(title: String, message: String) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = "确定"
	add_child(dialog)
	dialog.popup_centered()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_down"):
		if new_game_button.has_focus():
			if load_game_button.disabled:
				exit_button.grab_focus()
			else:
				load_game_button.grab_focus()
		elif load_game_button.has_focus():
			exit_button.grab_focus()
	elif event.is_action_pressed("ui_up"):
		if exit_button.has_focus():
			if load_game_button.disabled:
				new_game_button.grab_focus()
			else:
				load_game_button.grab_focus()
		elif load_game_button.has_focus():
			new_game_button.grab_focus()
