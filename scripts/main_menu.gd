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
	# 连接按钮信号
	new_game_button.pressed.connect(_on_new_game_pressed)
	load_game_button.pressed.connect(_on_load_game_pressed)
	exit_button.pressed.connect(_on_exit_pressed)
	
	# 检查是否有存档，如果没有则禁用"加载游戏"按钮
	if not GameManager.has_save_file():
		load_game_button.disabled = true
		load_game_button.modulate = Color(0.5, 0.5, 0.5, 1.0)
	
	# 设置版本号
	version_label.text = "v1.0"
	
	# 添加键盘支持
	new_game_button.grab_focus()

func _on_new_game_pressed() -> void:
	print("开始新游戏...")
	GameManager.start_new_game()
	new_game_started.emit()
	
	# 切换到主游戏场景
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_load_game_pressed() -> void:
	print("加载游戏...")
	if GameManager.load_game():
		load_game_requested.emit()
		
		# 切换到主游戏场景，存档数据会自动应用
		get_tree().change_scene_to_file("res://scenes/main.tscn")
	else:
		print("加载游戏失败！")
		# 显示错误提示
		_show_error_dialog("加载失败", "无法读取存档文件。")

func _on_exit_pressed() -> void:
	print("退出游戏")
	game_exited.emit()
	get_tree().quit()

func _show_error_dialog(title: String, message: String) -> void:
	# 创建简单的错误对话框
	var dialog = AcceptDialog.new()
	dialog.title = title
	dialog.dialog_text = message
	dialog.ok_button_text = "确定"
	add_child(dialog)
	dialog.popup_centered()

func _input(event: InputEvent) -> void:
	# 键盘导航支持
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
