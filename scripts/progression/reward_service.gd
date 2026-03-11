extends Node

func grant_gold(amount: int) -> bool:
	if amount <= 0:
		return false
	InventoryManager.add_gold(amount)
	GameEvents.emit_domain_event("reward_gold_granted", {"amount": amount})
	return true

func grant_item(item_id: String, quantity: int = 1) -> bool:
	if item_id.is_empty() or quantity <= 0:
		return false

	var item_data := ContentDB.get_item_definition(item_id)
	if item_data.is_empty():
		return false

	var added: bool = InventoryManager.add_item(item_data, quantity)
	if added:
		GameEvents.emit_domain_event("reward_item_granted", {"item_id": item_id, "quantity": quantity})
	return added

func grant_quest_rewards(quest_definition: Dictionary) -> bool:
	var rewards: Dictionary = quest_definition.get("rewards", {})
	var any_success: bool = false

	var exp_amount: int = int(rewards.get("experience", 0))
	if exp_amount > 0:
		var player := Utils.get_group_node("player")
		if player and player.has_method("add_experience"):
			player.add_experience(exp_amount)
			any_success = true
			GameEvents.emit_domain_event("reward_experience_granted", {"amount": exp_amount})

	var gold_amount: int = int(rewards.get("gold", 0))
	if gold_amount > 0:
		any_success = grant_gold(gold_amount) or any_success

	for item_reward in rewards.get("items", []):
		if not item_reward is Dictionary:
			continue
		var item_id: String = item_reward.get("item_id", item_reward.get("id", ""))
		var quantity: int = int(item_reward.get("quantity", 1))
		any_success = grant_item(item_id, quantity) or any_success

	return any_success
