class_name JournalScreen
extends PanelContainer

@onready var active_text: RichTextLabel = $Margin/VBox/Tabs/Active/ActiveText
@onready var completed_text: RichTextLabel = $Margin/VBox/Tabs/Completed/CompletedText
@onready var rewarded_text: RichTextLabel = $Margin/VBox/Tabs/Rewarded/RewardedText
@onready var close_button: Button = $Margin/VBox/CloseButton

var _is_open: bool = false

func _ready() -> void:
	visible = false
	close_button.pressed.connect(close_screen)

func toggle_screen() -> void:
	if _is_open:
		close_screen()
	else:
		open_screen()

func open_screen() -> void:
	if _is_open:
		return

	_is_open = true
	visible = true
	refresh()
	UIRouter.register_modal("journal", Callable(self, "close_screen"), 40, true)

func close_screen() -> void:
	if not _is_open:
		return

	_is_open = false
	visible = false
	UIRouter.unregister_modal("journal")

func is_open() -> bool:
	return _is_open

func refresh() -> void:
	var journal_data: Dictionary = QuestService.get_journal_view_data()
	active_text.text = _format_entries("进行中任务", journal_data.get("active", []))
	completed_text.text = _format_entries("已完成任务", journal_data.get("completed", []))
	rewarded_text.text = _format_entries("已领奖任务", journal_data.get("rewarded", []))

func _format_entries(title: String, entries: Array) -> String:
	var lines: PackedStringArray = [title]
	if entries.is_empty():
		lines.append("- 无")
		return "\n".join(lines)

	for entry in entries:
		if not entry is Dictionary:
			continue
		var quest_name: String = entry.get("name", entry.get("quest_id", "未知任务"))
		lines.append("- " + quest_name)
		for objective in entry.get("objectives", []):
			if objective is Dictionary:
				var objective_desc: String = objective.get("description", "")
				if objective_desc.is_empty():
					objective_desc = "%s %s (%d/%d)" % [
						objective.get("type", ""),
						objective.get("target", ""),
						int(objective.get("current", 0)),
						int(objective.get("required", 0))
					]
				lines.append("  " + objective_desc)

	return "\n".join(lines)
