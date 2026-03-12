class_name Main
extends Node2D

@onready var player := $Player

func _ready() -> void:
	App.current_scene_name = "main"
	MapService.set_active_map("main_world")
	GameEvents.emit_domain_event("scene_ready", {"scene_name": "main"})
