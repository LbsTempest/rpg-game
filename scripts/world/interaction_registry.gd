extends Node

var _sources: Dictionary = {}

func register_source(source_id: String, source: Node) -> void:
	if source_id.is_empty():
		return
	_sources[source_id] = source

func unregister_source(source_id: String) -> void:
	if source_id.is_empty():
		return
	_sources.erase(source_id)

func get_source(source_id: String) -> Node:
	return _sources.get(source_id)

func has_source(source_id: String) -> bool:
	return _sources.has(source_id)

func clear() -> void:
	_sources.clear()
