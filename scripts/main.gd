class_name Main
extends Node2D

@onready var player := $Player

func _ready() -> void:
	GameManager.current_scene_name = "main"
