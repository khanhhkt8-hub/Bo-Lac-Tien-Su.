extends Node
class_name InventorySystem

signal inventory_changed(items: Dictionary)

var items: Dictionary = {}

func add_item(item_id: String, amount: int) -> void:
	if item_id.is_empty() or amount <= 0:
		return
	items[item_id] = int(items.get(item_id, 0)) + amount
	inventory_changed.emit(items.duplicate())

func remove_item(item_id: String, amount: int) -> bool:
	if amount <= 0 or int(items.get(item_id, 0)) < amount:
		return false
	items[item_id] = int(items[item_id]) - amount
	if items[item_id] <= 0:
		items.erase(item_id)
	inventory_changed.emit(items.duplicate())
	return true

func get_amount(item_id: String) -> int:
	return int(items.get(item_id, 0))
