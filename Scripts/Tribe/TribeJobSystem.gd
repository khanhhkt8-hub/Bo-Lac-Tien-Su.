extends Node
## Offline profession assignment and resource production for adult tribe members.

signal job_assigned(resident_id: int, job_id: String)
signal production_changed(resource_id: String, amount: int)

const SAVE_PATH := "user://bo_lac_jobs.cfg"
const PRODUCTION_INTERVAL := 30.0
const JOBS := {
	"hunter": {"name": "Thợ săn", "output": "meat", "amount": 3},
	"gatherer": {"name": "Người hái lượm", "output": "berries", "amount": 4},
	"farmer": {"name": "Nông dân", "output": "food", "amount": 3},
	"crafter": {"name": "Thợ chế tác", "output": "tools", "amount": 1},
	"warrior": {"name": "Chiến binh", "output": "warrior_power", "amount": 2}
}

var assignments: Dictionary = {}
var stockpile: Dictionary = {"meat": 0, "berries": 0, "food": 0, "tools": 0, "warrior_power": 0}
var _production_timer: float = 0.0

func _ready() -> void:
	_load_state()

func _process(delta: float) -> void:
	_production_timer += delta
	if _production_timer < PRODUCTION_INTERVAL:
		return
	_production_timer -= PRODUCTION_INTERVAL
	_produce_resources()

func assign_job(resident_id: int, job_id: String) -> bool:
	if not JOBS.has(job_id):
		return false
	var resident := TribePopulation.get_resident(resident_id)
	if resident.is_empty() or int(resident.get("age", 0)) < 18:
		return false
	assignments[resident_id] = job_id
	resident["job"] = job_id
	TribePopulation.save_population()
	job_assigned.emit(resident_id, job_id)
	_save_state()
	return true

func get_job_name(job_id: String) -> String:
	if not JOBS.has(job_id):
		return "Chưa phân công"
	return str(JOBS[job_id].name)

func get_job_summary() -> Dictionary:
	var counts: Dictionary = {}
	for job_id in JOBS:
		counts[job_id] = 0
	for key in assignments:
		var resident_id := int(key)
		var resident := TribePopulation.get_resident(resident_id)
		var job_id := str(assignments[key])
		if not resident.is_empty() and JOBS.has(job_id):
			counts[job_id] = int(counts[job_id]) + 1
	return {"counts": counts, "stockpile": stockpile.duplicate()}

func add_to_stockpile(resource_id: String, amount: int) -> void:\n\tif not stockpile.has(resource_id) or amount <= 0:\n\t\treturn\n\tstockpile[resource_id] = int(stockpile[resource_id]) + amount\n\tproduction_changed.emit(resource_id, int(stockpile[resource_id]))\n\t_save_state()\n\nfunc raid_stockpile(resource_id: String, requested_amount: int) -> int:
	if not stockpile.has(resource_id) or requested_amount <= 0:
		return 0
	var stolen := mini(int(stockpile[resource_id]), requested_amount)
	stockpile[resource_id] = int(stockpile[resource_id]) - stolen
	if stolen > 0:
		production_changed.emit(resource_id, int(stockpile[resource_id]))
		_save_state()
	return stolen

func _produce_resources() -> void:
	var produced: Dictionary = {}
	for key in assignments:
		var resident_id := int(key)
		var resident := TribePopulation.get_resident(resident_id)
		var job_id := str(assignments[key])
		if resident.is_empty() or not JOBS.has(job_id):
			continue
		var definition: Dictionary = JOBS[job_id]
		var resource_id := str(definition.output)
		var amount := int(definition.amount)
		stockpile[resource_id] = int(stockpile.get(resource_id, 0)) + amount
		produced[resource_id] = int(produced.get(resource_id, 0)) + amount
	for resource_id in produced:
		production_changed.emit(resource_id, int(stockpile[resource_id]))
	_save_state()

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("jobs", "assignments", assignments)
	config.set_value("jobs", "stockpile", stockpile)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	assignments = config.get_value("jobs", "assignments", {})
	var saved_stockpile: Dictionary = config.get_value("jobs", "stockpile", {})
	for resource_id in stockpile:
		stockpile[resource_id] = maxi(0, int(saved_stockpile.get(resource_id, 0)))
	# Discard assignments for residents who no longer exist or are not adults.
	for key in assignments.keys():
		var resident := TribePopulation.get_resident(int(key))
		if resident.is_empty() or int(resident.get("age", 0)) < 18 or not JOBS.has(str(assignments[key])):
			assignments.erase(key)
		else:
			resident["job"] = str(assignments[key])
