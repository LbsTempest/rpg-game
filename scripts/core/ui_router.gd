extends Node

var _modal_registry: Array[Dictionary] = []
var _order_counter: int = 0

func register_modal(id: String, close_callable: Callable = Callable(), priority: int = 0, consume_cancel: bool = true) -> void:
	if id.is_empty():
		return

	unregister_modal(id)
	_modal_registry.append(
		{
			"id": id,
			"close_callable": close_callable,
			"priority": priority,
			"order": _order_counter,
			"consume_cancel": consume_cancel
		}
	)
	_order_counter += 1

func unregister_modal(id: String) -> void:
	for index in range(_modal_registry.size() - 1, -1, -1):
		if _modal_registry[index].get("id", "") == id:
			_modal_registry.remove_at(index)

func has_modal() -> bool:
	return not _modal_registry.is_empty()

func clear() -> void:
	_modal_registry.clear()

func close_top_modal() -> bool:
	var top_modal := _get_top_modal()
	if top_modal.is_empty():
		return false

	var close_callable: Callable = top_modal.get("close_callable", Callable())
	var consume_cancel: bool = bool(top_modal.get("consume_cancel", true))

	if close_callable.is_valid():
		close_callable.call()
		return true

	return consume_cancel

func _get_top_modal() -> Dictionary:
	if _modal_registry.is_empty():
		return {}

	var top := _modal_registry[0]
	for entry in _modal_registry:
		var is_higher_priority: bool = entry["priority"] > top["priority"]
		var same_priority_newer: bool = entry["priority"] == top["priority"] and entry["order"] > top["order"]
		if is_higher_priority or same_priority_newer:
			top = entry

	return top
