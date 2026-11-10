extends Node
## Offline profession assignment and resource production for adult tribe members.

signal job_assigned(resident_id: int, job_id: String)
signal production_changed(resource_id: String, amount: int)

const SAVE_PATH := "user://bo_lac_jobs.cfg"
const PRODUCTION_INTERVAL := 30.0
const JOBS := {
	"hunter": {"name": "Thợ săn", "output": "meat", "amount": 3},
	"gatherer": {"name": "Người hái lượm", "output": "fruit", "amount": 4},
	"fisher": {"name": "Ngư dân", "output": "fish", "amount": 4},
	"water_carrier": {"name": "Người lấy nước", "output": "water", "amount": 5},
	"herbalist": {"name": "Người hái thuốc", "output": "herbs", "amount": 3},
	"medic": {"name": "Thầy thuốc", "output": "medical_care", "amount": 1},
	"orchardist": {"name": "Người thu hái trái cây", "output": "fruit", "amount": 5},
	"poultry": {"name": "Người nuôi gia cầm", "output": "eggs", "amount": 2},
	"miner": {"name": "Thợ khai mỏ", "output": "stone", "amount": 3},
	"farmer": {"name": "Nông dân", "output": "food", "amount": 3},
	"crafter": {"name": "Thợ chế tác", "output": "tools", "amount": 1},
	"warrior": {"name": "Chiến binh", "output": "warrior_power", "amount": 2},
	"night_guard": {"name": "Lính canh đêm", "output": "warrior_power", "amount": 1},
	"scout": {"name": "Trinh sát", "output": "maps", "amount": 1}
}

var assignments: Dictionary = {}
var stockpile: Dictionary = {"wood": 0, "stone": 0, "water": 0, "herbs": 0, "hide": 0, "bone": 0, "flint": 0, "ore": 0, "reeds": 0, "ice": 0, "meat": 0, "berries": 0, "fish": 0, "fruit": 0, "chicken": 0, "duck": 0, "eggs": 0, "clay": 0, "food": 0, "tools": 0, "warrior_power": 0, "maps": 0, "trophy_heartland": 0, "trophy_primeval_forest": 0, "trophy_grassland": 0, "trophy_swampland": 0, "trophy_cavern": 0, "trophy_frostlands": 0}
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

func add_to_stockpile(resource_id: String, amount: int) -> void:
	if not stockpile.has(resource_id) or amount <= 0:
		return
	stockpile[resource_id] = int(stockpile[resource_id]) + amount
	production_changed.emit(resource_id, int(stockpile[resource_id]))
	_save_state()

func raid_stockpile(resource_id: String, requested_amount: int) -> int:
	if not stockpile.has(resource_id) or requested_amount <= 0:
		return 0
	var stolen := mini(int(stockpile[resource_id]), requested_amount)
	stockpile[resource_id] = int(stockpile[resource_id]) - stolen
	if stolen > 0:
		production_changed.emit(resource_id, int(stockpile[resource_id]))
		_save_state()
	return stolen

func _produce_resources() -> void:
	_auto_assign_emergency_jobs()
	var produced: Dictionary = {}
	for key in assignments:
		var resident_id := int(key)
		var resident := TribePopulation.get_resident(resident_id)
		var job_id := str(assignments[key])
		if resident.is_empty() or not JOBS.has(job_id):
			continue
		var definition: Dictionary = JOBS[job_id]
		if job_id == "medic":
			_medic_treat_one_resident()
			continue
		var resource_id := str(definition.output)
		var amount := int(definition.amount)
		stockpile[resource_id] = int(stockpile.get(resource_id, 0)) + amount
		produced[resource_id] = int(produced.get(resource_id, 0)) + amount
	for resource_id in produced:
		production_changed.emit(resource_id, int(stockpile[resource_id]))
	_save_state()

## Khi kho sinh tồn xuống thấp, tự giao việc cho người trưởng thành chưa có nghề.
## Không thay đổi bất kỳ nghề nào người chơi đã phân công.
func _auto_assign_emergency_jobs() -> void:
	# Thu hồi nghề của người đã mất để vị trí lao động được dùng lại.
	var stale_ids: Array = []
	for key in assignments.keys():
		if TribePopulation.get_resident(int(key)).is_empty():
			stale_ids.append(key)
	for key in stale_ids:
		assignments.erase(key)
	var summary := TribePopulation.get_population_summary()
	var living_adults := int(summary.get("adults", 0)) + int(summary.get("elders", 0))
	if living_adults <= 0:
		return
	var food_total := 0
	for resource_id in ["food", "meat", "fish", "fruit", "berries", "chicken", "duck", "eggs"]:
		food_total += int(stockpile.get(resource_id, 0))
	var water_total := int(stockpile.get("water", 0))
	var food_limit := maxi(10, living_adults * 2)
	var water_limit := maxi(10, living_adults * 2)
	var sick_count := 0
	for person in TribePopulation.residents:
		if bool(person.get("alive", true)) and bool(person.get("illness", false)):
			sick_count += 1
	var food_jobs := ["farmer", "gatherer", "fisher", "hunter", "orchardist", "poultry"]
	var assigned_any := false
	var emergency_slots := 2
	for person in TribePopulation.residents:
		if emergency_slots <= 0:
			break
		if not bool(person.get("alive", true)) or int(person.get("age", 0)) < 18:
			continue
		if str(person.get("role", "")) == "chieftain":
			continue
		var resident_id := int(person.get("id", -1))
		if assignments.has(resident_id) or assignments.has(str(resident_id)):
			continue
		var selected_job := ""
		var food_ratio := float(food_total) / float(food_limit)
		var water_ratio := float(water_total) / float(water_limit)
		if sick_count > 0 and int(stockpile.get("herbs", 0)) < sick_count * 2:
			selected_job = "herbalist"
			sick_count -= 1
		elif water_total < water_limit and (food_total >= food_limit or water_ratio <= food_ratio):
			selected_job = "water_carrier"
			water_total += 5
		elif food_total < food_limit:
			selected_job = food_jobs[mini(food_jobs.size() - 1, int(food_total / 5.0) % food_jobs.size())]
			food_total += 4
		elif water_total < water_limit:
			selected_job = "water_carrier"
			water_total += 5
		if selected_job.is_empty():
			break
		assignments[resident_id] = selected_job
		person["job"] = selected_job
		job_assigned.emit(resident_id, selected_job)
		emergency_slots -= 1
		assigned_any = true
	if assigned_any:
		TribePopulation.save_population()
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


## Thầy thuốc dùng 1 bó thảo dược để hồi 15 máu cho một người bị thương mỗi chu kỳ.
func _medic_treat_one_resident() -> void:
	if int(stockpile.get("herbs", 0)) <= 0:
		return
	var target: Dictionary = {}
	var lowest_health := 100.0
	for person in TribePopulation.residents:
		if not bool(person.get("alive", true)):
			continue
		var current_health := float(person.get("health", 100.0))
		if current_health < lowest_health:
			lowest_health = current_health
			target = person
	if target.is_empty() or lowest_health >= 100.0:
		return
	if raid_stockpile("herbs", 1) <= 0:
		return
	target["health"] = minf(100.0, lowest_health + 15.0)
	TribePopulation.save_population()
	if TribePopulation.has_method("_emit_population"):
		TribePopulation._emit_population()
