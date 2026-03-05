extends Node

# 音频总线
enum Bus { MASTER, MUSIC, SFX, UI }

# 音量设置（0.0 - 1.0）
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var ui_volume: float = 0.9

# 预加载的音效
var sound_effects: Dictionary = {}
var music_tracks: Dictionary = {}

# 音频播放器节点
@onready var music_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var ui_player: AudioStreamPlayer = AudioStreamPlayer.new()

# 音效路径（需要用户添加实际音频文件）
const SOUND_PATHS := {
	# 战斗音效
	"attack": "res://assets/audio/sfx/attack.wav",
	"hit": "res://assets/audio/sfx/hit.wav",
	"defend": "res://assets/audio/sfx/defend.wav",
	"victory": "res://assets/audio/sfx/victory.wav",
	"defeat": "res://assets/audio/sfx/defeat.wav",
	
	# UI音效
	"click": "res://assets/audio/sfx/click.wav",
	"hover": "res://assets/audio/sfx/hover.wav",
	"open_menu": "res://assets/audio/sfx/open_menu.wav",
	"close_menu": "res://assets/audio/sfx/close_menu.wav",
	
	# 物品音效
	"equip": "res://assets/audio/sfx/equip.wav",
	"use_item": "res://assets/audio/sfx/use_item.wav",
	"get_item": "res://assets/audio/sfx/get_item.wav",
	
	# 移动音效
	"step": "res://assets/audio/sfx/step.wav",
	"encounter": "res://assets/audio/sfx/encounter.wav"
}

# BGM路径
const MUSIC_PATHS := {
	"main_theme": "res://assets/audio/bgm/main_theme.ogg",
	"battle": "res://assets/audio/bgm/battle.ogg",
	"victory": "res://assets/audio/bgm/victory.ogg",
	"village": "res://assets/audio/bgm/village.ogg",
	"dungeon": "res://assets/audio/bgm/dungeon.ogg"
}

func _ready() -> void:
	# 添加音频播放器到场景树
	add_child(music_player)
	add_child(sfx_player)
	add_child(ui_player)
	
	# 设置音频总线
	music_player.bus = "Music"
	sfx_player.bus = "SFX"
	ui_player.bus = "UI"
	
	# 初始化音量
	_update_volumes()
	
	print("AudioManager 初始化完成")

func _update_volumes() -> void:
	# 检查总线是否存在，避免报错
	var bus_count: int = AudioServer.get_bus_count()
	AudioServer.set_bus_volume_db(Bus.MASTER, linear_to_db(master_volume))
	if bus_count > Bus.MUSIC:
		AudioServer.set_bus_volume_db(Bus.MUSIC, linear_to_db(music_volume))
	if bus_count > Bus.SFX:
		AudioServer.set_bus_volume_db(Bus.SFX, linear_to_db(sfx_volume))
	if bus_count > Bus.UI:
		AudioServer.set_bus_volume_db(Bus.UI, linear_to_db(ui_volume))

# ========== 音效播放 ==========

func play_sfx(sound_name: String) -> void:
	"""播放音效（战斗、动作等）"""
	var path: String = SOUND_PATHS.get(sound_name, "")
	if path.is_empty():
		return
	
	if not sound_effects.has(sound_name):
		if FileAccess.file_exists(path):
			var stream: AudioStream = load(path)
			sound_effects[sound_name] = stream
		else:
			print("音效文件不存在: ", path)
			return
	
	sfx_player.stream = sound_effects[sound_name]
	sfx_player.play()

func play_ui_sound(sound_name: String) -> void:
	"""播放UI音效"""
	var path: String = SOUND_PATHS.get(sound_name, "")
	if path.is_empty():
		return
	
	if not sound_effects.has(sound_name):
		if FileAccess.file_exists(path):
			var stream: AudioStream = load(path)
			sound_effects[sound_name] = stream
		else:
			return
	
	ui_player.stream = sound_effects[sound_name]
	ui_player.play()

# ========== 背景音乐 ==========

func play_music(track_name: String, fade_duration: float = 1.0) -> void:
	"""播放背景音乐"""
	var path: String = MUSIC_PATHS.get(track_name, "")
	if path.is_empty():
		return
	
	if not music_tracks.has(track_name):
		if FileAccess.file_exists(path):
			var stream: AudioStream = load(path)
			stream.loop = true
			music_tracks[track_name] = stream
		else:
			print("音乐文件不存在: ", path)
			return
	
	# 如果正在播放同一首音乐，不做任何操作
	if music_player.playing and music_player.stream == music_tracks[track_name]:
		return
	
	# 淡入淡出切换
	if music_player.playing:
		_fade_out_music(fade_duration / 2)
		await get_tree().create_timer(fade_duration / 2).timeout
	
	music_player.stream = music_tracks[track_name]
	music_player.play()
	_fade_in_music(fade_duration / 2)

func stop_music(fade_duration: float = 1.0) -> void:
	"""停止背景音乐"""
	if music_player.playing:
		_fade_out_music(fade_duration)
		await get_tree().create_timer(fade_duration).timeout
		music_player.stop()

func _fade_in_music(duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), duration)

func _fade_out_music(duration: float) -> void:
	var tween: Tween = create_tween()
	tween.tween_property(music_player, "volume_db", linear_to_db(0.001), duration)

# ========== 音量控制 ==========

func set_master_volume(volume: float) -> void:
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(Bus.MASTER, linear_to_db(master_volume))

func set_music_volume(volume: float) -> void:
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(Bus.MUSIC, linear_to_db(music_volume))

func set_sfx_volume(volume: float) -> void:
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(Bus.SFX, linear_to_db(sfx_volume))

func set_ui_volume(volume: float) -> void:
	ui_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(Bus.UI, linear_to_db(ui_volume))

# ========== 便捷方法 ==========

func play_attack_sound() -> void:
	play_sfx("attack")

func play_hit_sound() -> void:
	play_sfx("hit")

func play_victory_sound() -> void:
	play_sfx("victory")
	play_music("victory", 0.5)

func play_defeat_sound() -> void:
	play_sfx("defeat")

func play_button_click() -> void:
	play_ui_sound("click")

func play_menu_open() -> void:
	play_ui_sound("open_menu")

func play_equip_sound() -> void:
	play_sfx("equip")

func play_get_item_sound() -> void:
	play_sfx("get_item")

func play_encounter_sound() -> void:
	play_sfx("encounter")
	play_music("battle", 0.5)
