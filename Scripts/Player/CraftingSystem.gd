extends Node
class_name CraftingSystem

signal crafted(item_id: String)

var inventory: InventorySystem

const RECIPES := {
	"stone_axe": {"wood": 3, "stone": 2},
	"stone_spear": {"wood": 2, "stone": 1},
	"campfire": {"wood": 5, "stone": 3}
}

func setup(target_inventory: InventorySystem) -> void:
	inventory = target_inventory

func can_craft(item_id: String) -> bool:
	if inventory == null or not RECIPES.has(item_id):
		return false
	var recipe: Dictionary = RECIPES[item_id]
	for resource_id in recipe:
		if inventory.get_amount(resource_id) < int(recipe[resource_id]):
			return false
	return true

func craft(item_id: String) -> bool:
	if not can_craft(item_id):
		return false
	var recipe: Dictionary = RECIPES[item_id]
	for resource_id in recipe:
		if not inventory.remove_item(resource_id, int(recipe[resource_id])):
			return false
	inventory.add_item(item_id, 1)
	crafted.emit(item_id)
	return true

func get_recipe_text(item_id: String) -> String:
	if not RECIPES.has(item_id):
		return "Không có công thức"
	var parts: PackedStringArray = []
	for resource_id in RECIPES[item_id]:
		parts.append("%s x%d" % [str(resource_id), int(RECIPES[item_id][resource_id])])
	return ", ".join(parts)
