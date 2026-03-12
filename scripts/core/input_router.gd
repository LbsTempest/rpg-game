extends Node

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if UIRouter.close_top_modal():
			get_viewport().set_input_as_handled()
			return
		App.toggle_pause()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_focus_next") and Input.is_action_pressed("ui_accept"):
		App.save_game()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("open_inventory"):
		_toggle_inventory()
		get_viewport().set_input_as_handled()

func _toggle_inventory() -> void:
	var ui_node = Utils.get_group_node("ui")
	if ui_node and ui_node.has_method("toggle_inventory_from_router"):
		ui_node.toggle_inventory_from_router()
