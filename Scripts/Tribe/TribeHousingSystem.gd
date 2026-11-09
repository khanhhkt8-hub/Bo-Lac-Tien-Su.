extends Node
## Offline housing progression for the prehistoric tribe.
## Each house can be upgraded through five levels. Materials are stored locally.

signal house_upgraded(house_id: int, new_level: int)
signal materials_changed(wood: int, stone: int)

const SAVE_PATH := "user://bo_lac_housing.cfg"
const MAX_LEVEL := 5
const UPGRADE_COSTS := {
	2: {"wood": 30, "stone": 10},
	3: {"wood": 55, "stone": 25},
	4: {"wood": 85, "stone": 45},
	5: {"wood": 130, "stone": 75}
}

var houses: Array[Dictionary] = []
var wood: int = 0
var stone: int = 0
var _next_house_id: int = 1

func _ready() -> void:
	load_state()
	if houses.is_empty():
		create_house("Nhà bộ lạc")

func create_house(house_name: String) -> int:
	var house_id := _next_house_id
	_next_house_id += 1
	houses.append({
		"id": house_id,
		"name": house_name,
		"level": 1,
		"capacity": 2,
		"resident_ids": []
	})
	save_state()
	return house_id

func add_materials(add_wood: int, add_stone: int) -> void:
	wood = maxi(0, wood + add_wood)
	stone = maxi(0, stone + add_stone)
	materials_changed.emit(wood, stone)
	save_state()

func get_upgrade_cost(next_level: int) -> Dictionary:
	return UPGRADE_COSTS.get(next_level, {}).duplicate()

func upgrade_house(house_id: int) -> bool:
	var house := _find_house(house_id)
	if house.is_empty():
		return false
	var current_level := int(house.level)
	if current_level >= MAX_LEVEL:
		return false
	var next_level := current_level + 1
	var cost: Dictionary = get_upgrade_cost(next_level)
	if cost.is_empty() or wood < int(cost.wood) or stone < int(cost.stone):
		return false
	wood -= int(cost.wood)
	stone -= int(cost.stone)
	house.level = next_level
	house.capacity = next_level * 2
	house_upgraded.emit(house_id, next_level)
	materials_changed.emit(wood, stone)
	save_state()
	return true

func assign_resident(house_id: int, resident_id: int) -> bool:
	var house := _find_house(house_id)
	var resident := TribePopulation.get_resident(resident_id)
	if house.is_empty() or resident.is_empty():
		return false
	if house.resident_ids.has(resident_id):
		return true
	# Remove stale/dead residents before checking available capacity.
	_prune_assignments()
	var currently_assigned := false
	for other in houses:
		if other.resident_ids.has(resident_id):
			currently_assigned = true
			break
	if not currently_assigned and house.resident_ids.size() >= int(house.capacity):
		return false
	for other in houses:
		other.resident_ids.erase(resident_id)
	house.resident_ids.append(resident_id)
	save_state()
	return true

func _prune_assignments() -> void:
	for house in houses:
		var valid_ids: Array = []
		for resident_id in house.resident_ids:
			if not TribePopulation.get_resident(int(resident_id)).is_empty() and not valid_ids.has(resident_id):
				valid_ids.append(resident_id)
		house.resident_ids = valid_ids

func get_housing_summary() -> Dictionary:
	_prune_assignments()
	var total_capacity := 0
	var assigned := 0
	for house in houses:
		total_capacity += int(house.capacity)
		assigned += house.resident_ids.size()
	var total_residents := int(TribePopulation.get_population_summary().total)
	return {
		"houses": houses.size(),
		"capacity": total_capacity,
		"assigned": assigned,
		"homeless": maxi(0, total_residents - assigned)
	}

func _find_house(house_id: int) -> Dictionary:
	for house in houses:
		if int(house.id) == house_id:
			return house
	return {}

func save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("housing", "houses", houses)
	config.set_value("housing", "wood", wood)
	config.set_value("housing", "stone", stone)
	config.set_value("housing", "next_house_id", _next_house_id)
	config.save(SAVE_PATH)

func load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	houses.clear()
	for house in config.get_value("housing", "houses", []):
		houses.append(house)
	wood = int(config.get_value("housing", "wood", 0))
	stone = int(config.get_value("housing", "stone", 0))
	_next_house_id = int(config.get_value("housing", "next_house_id", houses.size() + 1))
