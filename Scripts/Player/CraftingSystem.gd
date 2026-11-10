extends Node
class_name CraftingSystem

signal crafted(item_id: String)

var inventory: InventorySystem

const RECIPE_OUTPUTS := {"arrows": 5}

const RECIPES := {
	"stone_axe": {"wood": 3, "stone": 2},
	"stone_spear": {"wood": 2, "stone": 1},
	"campfire": {"wood": 5, "stone": 3},
	"bow": {"wood": 4, "stone": 2},
	"arrows": {"wood": 2, "stone": 1},
	"fur_cloak": {"hide": 8, "bone": 3},
	"herbal_antidote": {"herbs": 3, "berries": 2},
	"torch": {"wood": 3, "reeds": 2},
	"companion_armor": {"hide": 6, "bone": 4},
	"companion_fang": {"bone": 6, "stone": 3},
	"relic_mammoth_axe": {"trophy_heartland": 1, "ore": 10, "bone": 8},
	"relic_saber_blade": {"trophy_primeval_forest": 1, "hide": 12, "bone": 8},
	"relic_thunder_spear": {"trophy_grassland": 1, "ore": 12, "wood": 8},
	"relic_swamp_claw": {"trophy_swampland": 1, "herbs": 10, "hide": 8},
	"relic_cavern_hammer": {"trophy_cavern": 1, "ore": 14, "stone": 10},
	"relic_frost_bow": {"trophy_frostlands": 1, "ice": 12, "wood": 10}
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
	inventory.add_item(item_id, int(RECIPE_OUTPUTS.get(item_id, 1)))
	crafted.emit(item_id)
	return true

func get_recipe_text(item_id: String) -> String:
	if not RECIPES.has(item_id):
		return "Không có công thức"
	var parts: PackedStringArray = []
	for resource_id in RECIPES[item_id]:
		parts.append("%s x%d" % [str(resource_id), int(RECIPES[item_id][resource_id])])
	return ", ".join(parts)
