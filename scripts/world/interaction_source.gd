class_name InteractionSource
extends Area2D

signal triggered(source_id: String, body: Node2D, result: Dictionary)
signal trigger_failed(source_id: String, body: Node2D, result: Dictionary)

@export var source_id: String = ""
@export var action_id: String = ""
@export var action_payload: Dictionary = {}
@export var conditions: Dictionary = {}
@export var one_shot: bool = false
@export var trigger_on_body_enter: bool = true
@export var required_group: String = "player"

var _is_active: bool = true

func _ready() -> void:
	if source_id.is_empty():
		source_id = name
	InteractionRegistry.register_source(source_id, self)
	if trigger_on_body_enter:
		body_entered.connect(_on_body_entered)

func _exit_tree() -> void:
	InteractionRegistry.unregister_source(source_id)

func set_active(active: bool) -> void:
	_is_active = active

func trigger(body: Node2D = null, context: Dictionary = {}) -> Dictionary:
	if not _is_active:
		return {"success": false, "message": "source_inactive", "data": {}}

	var action_data := {
		"id": action_id,
		"payload": action_payload,
		"conditions": conditions
	}
	var action_context := {
		"source": "interaction_source",
		"source_id": source_id,
		"node": self,
		"body": body
	}
	action_context.merge(context, true)
	var result: Dictionary = TriggerRouter.execute_action(action_data, {}, action_context)

	if result.get("success", false):
		triggered.emit(source_id, body, result)
		GameEvents.emit_domain_event("interaction_source_triggered", {"source_id": source_id, "action": action_id})
		if one_shot:
			_is_active = false
	else:
		trigger_failed.emit(source_id, body, result)

	return result

func _on_body_entered(body: Node2D) -> void:
	if not _is_active:
		return
	if required_group.is_empty() or body.is_in_group(required_group):
		trigger(body)
