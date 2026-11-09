extends Node
class_name InventorySystem

signal inventory_changed(items: Dictionary)

const SAVE_PATH := "user://bo_lac_inventory.cfg"
var items: Dictionary = {}

func _ready() -> void:
	load_inventory()

func add_item(item_id: String, amount: int) -> void:
	if item_id.is_empty() or amount <= 0:
		return
	items[item_id] = int(items.get(item_id, 0)) + amount
	save_inventory()
	inventory_changed.emit(items.duplicate())

func remove_item(item_id: String, amount: int) -> bool:
	if amount <= 0 or int(items.get(item_id, 0)) < amount:
		return false
	items[item_id] = int(items[item_id]) - amount
	if items[item_id] <= 0:
		items.erase(item_id)
	save_inventory()
	inventory_changed.emit(items.duplicate())
	return true

func get_amount(item_id: String) -> int:
	return int(items.get(item_id, 0))

func save_inventory() -> void:
	var config := ConfigFile.new()
	config.set_value("inventory", "items", items)
	config.save(SAVE_PATH)

func load_inventory() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Dictionary = config.get_value("inventory", "items", {})
	items.clear()
	for item_id in saved:
		var amount := int(saved[item_id])
		if not str(item_id).is_empty() and amount > 0:
			items[str(item_id)] = amount
	inventory_changed.emit(items.duplicate())
