class_name CycleSummaryScreen
extends Control

@onready var title_label: Label = $VBoxContainer/TitleLabel
@onready var detail_label: Label = $VBoxContainer/DetailLabel
@onready var confirm_button: Button = $VBoxContainer/ConfirmButton

func _ready() -> void:
	visible = false
	confirm_button.pressed.connect(_on_confirm_pressed)

func show_summary(summary: Dictionary, cycle_index: int) -> void:
	visible = true
	title_label.text = "二周目开启 - 第 %d 周目" % cycle_index
	detail_label.text = _build_detail_text(summary)
	confirm_button.grab_focus()

func _build_detail_text(summary: Dictionary) -> String:
	var lines: PackedStringArray = []
	lines.append("继承金币: %d" % int(summary.get("carried_gold", 0)))
	lines.append("继承技能数: %d" % int(summary.get("carried_skills", 0)))

	var carried_items: Array = summary.get("carried_items", [])
	if carried_items.is_empty():
		lines.append("继承道具: 无")
	else:
		var item_lines: PackedStringArray = []
		for item_entry in carried_items:
			if not item_entry is Dictionary:
				continue
			item_lines.append("%s x%d" % [String(item_entry.get("item_id", "")), int(item_entry.get("quantity", 0))])
		lines.append("继承道具: %s" % ", ".join(item_lines))

	return "\n".join(lines)

func _on_confirm_pressed() -> void:
	visible = false
