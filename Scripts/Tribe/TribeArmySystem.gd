extends Node
## Offline army roster. Only adult residents with the warrior profession can enlist.

signal army_changed

const SAVE_PATH := "user://bo_lac_army.cfg"
const UNIT_TYPES := {
	"spear": {"name": "Giáo binh", "power": 12},
	"archer": {"name": "Cung thủ", "power": 15},
	"guard": {"name": "Vệ binh tinh nhuệ", "power": 18}
}

var units: Dictionary = {}
var _next_type_index: int = 0
var _unit_order: Array[String] = ["spear", "archer", "guard"]

func _ready() -> void:
	_load_state()

func enlist(resident_id: int, unit_type: String = "") -> bool:
	var resident := TribePopulation.get_resident(resident_id)
	if resident.is_empty() or int(resident.get("age", 0)) < 18:
		return false
	if str(TribeJobSystem.assignments.get(resident_id, "")) != "warrior":
		return false
	if unit_type.is_empty():
		unit_type = _unit_order[_next_type_index]
		_next_type_index = (_next_type_index + 1) % _unit_order.size()
	if not UNIT_TYPES.has(unit_type):
		return false
	units[resident_id] = unit_type
	_save_state()
	army_changed.emit()
	return true

func dismiss(resident_id: int) -> bool:
	if not units.has(resident_id):
		return false
	units.erase(resident_id)
	_save_state()
	army_changed.emit()
	return true

func get_unit_type(resident_id: int) -> String:
	return str(units.get(resident_id, ""))

func get_army_summary() -> Dictionary:
	var counts := {"spear": 0, "archer": 0, "guard": 0}
	var power := 0
	var valid_units: Dictionary = {}
	for key in units:
		var resident_id := int(key)
		var resident := TribePopulation.get_resident(resident_id)
		var unit_type := str(units[key])
		if resident.is_empty() or not UNIT_TYPES.has(unit_type):
			continue
		if str(TribeJobSystem.assignments.get(resident_id, "")) != "warrior":
			continue
		valid_units[resident_id] = unit_type
		counts[unit_type] = int(counts[unit_type]) + 1
		var definition: Dictionary = UNIT_TYPES[unit_type]
		power += int(definition.power) + int(resident.get("strength", 0)) / 5
	if valid_units.size() != units.size():
		units = valid_units
		_save_state()
	return {"total": valid_units.size(), "spear": counts.spear, "archer": counts.archer, "guard": counts.guard, "power": power}

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("army", "units", units)
	config.set_value("army", "next_type_index", _next_type_index)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	units = config.get_value("army", "units", {})
	_next_type_index = clampi(int(config.get_value("army", "next_type_index", 0)), 0, _unit_order.size() - 1)
