class_name DialoguePresenter
extends RefCounted

func build_story_dialogue(segment_definition: Dictionary, step_index: int = 0) -> Array[Dictionary]:
	var dialogue_data: Array[Dictionary] = []
	if segment_definition.is_empty():
		return dialogue_data

	var steps: Array = segment_definition.get("steps", [])
	if steps.is_empty():
		return dialogue_data

	var start_index: int = clampi(step_index, 0, steps.size() - 1)
	for idx in range(start_index, steps.size()):
		var step = steps[idx]
		if not (step is Dictionary):
			continue

		var dialogue_entry: Dictionary = {
			"text": String(step.get("text", "...")),
			"type": String(step.get("type", "normal"))
		}
		if step.has("speaker"):
			dialogue_entry["speaker"] = String(step.get("speaker", ""))
		if step.has("options") and step["options"] is Array:
			dialogue_entry["options"] = _build_branch_options(step["options"])
		dialogue_data.append(dialogue_entry)

	return dialogue_data

func _build_branch_options(raw_options: Array) -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for option in raw_options:
		if option is Dictionary:
			options.append(option.duplicate(true))
	return options
