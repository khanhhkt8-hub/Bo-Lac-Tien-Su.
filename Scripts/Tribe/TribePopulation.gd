extends Node
## Offline tribe population and life-cycle simulation.
## Time is simulated: one in-game year passes every 20 real minutes by default.

signal population_changed(total: int, children: int, adults: int, elders: int)
signal resident_died(resident_name: String)
signal child_born(resident_name: String)
signal leader_changed(old_leader: Dictionary, new_leader: Dictionary)

const SAVE_PATH := "user://bo_lac_population.cfg"
const SECONDS_PER_YEAR := 1200.0
const ADULT_AGE := 18
const ELDER_AGE := 60
const MAX_AGE := 90
const LEADER_RETIREMENT_AGE := 70

var residents: Array[Dictionary] = []
var _year_accumulator: float = 0.0
var _next_id: int = 1
var leader_id: int = -1
var _load_leader_id: int = -1

func _ready() -> void:
	load_population()
	if residents.is_empty():
		leader_id = add_resident("Tộc trưởng đời thứ nhất", 32, "male", "chieftain")
		add_resident("Bạn đời", 29, "female")
	else:
		leader_id = _load_leader_id
	if get_leader().is_empty():
		elect_new_leader()
	_emit_population()

func _process(delta: float) -> void:
	_year_accumulator += delta
	while _year_accumulator >= SECONDS_PER_YEAR:
		_year_accumulator -= SECONDS_PER_YEAR
		_advance_one_year()

func add_resident(resident_name: String, age: int, sex: String, role: String = "villager") -> int:
	if age < 0 or sex not in ["male", "female"]:
		return -1
	var resident_id := _next_id
	_next_id += 1
	residents.append({
		"id": resident_id, "name": resident_name, "age": age,
		"sex": sex, "role": role, "partner_id": -1,
		"health": 100.0, "food": 20, "strength": 10, "stamina": 10, "alive": true, "in_daycare": false
	})
	_emit_population()
	save_population()
	return resident_id

func recruit_migrant(resident_name: String, age: int, sex: String, role: String = "migrant") -> int:
	return add_resident(resident_name, age, sex, role)

func get_leader() -> Dictionary:
	return _find_resident(leader_id)

func elect_new_leader() -> Dictionary:
	var previous := get_leader().duplicate(true)
	var candidates: Array[Dictionary] = []
	for person in residents:
		if not bool(person.get("alive", true)) or int(person.get("age", 0)) < ADULT_AGE:
			continue
		candidates.append(person)
	if candidates.is_empty():
		leader_id = -1
		if not previous.is_empty():
			leader_changed.emit(previous, {})
		save_population()
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _leadership_score(a) > _leadership_score(b)
	)
	var chosen: Dictionary = candidates[0]
	leader_id = int(chosen.id)
	chosen["role"] = "chieftain"
	for person in residents:
		if int(person.get("id", -1)) != leader_id and str(person.get("role", "")) == "chieftain":
			person["role"] = "villager"
	leader_changed.emit(previous, chosen.duplicate(true))
	save_population()
	return chosen

func _leadership_score(person: Dictionary) -> float:
	var age := int(person.get("age", 18))
	var prime_age_bonus := 25.0 if age >= 25 and age <= 55 else 0.0
	return float(person.get("health", 0.0)) * 0.35 + float(person.get("strength", 0)) * 2.0 + float(person.get("stamina", 0)) * 1.5 + float(person.get("experience", 0)) * 2.5 + prime_age_bonus

func pair_residents(first_id: int, second_id: int) -> bool:
	var first := _find_resident(first_id)
	var second := _find_resident(second_id)
	if first.is_empty() or second.is_empty():
		return false
	if int(first.age) < ADULT_AGE or int(second.age) < ADULT_AGE:
		return false
	if first.sex == second.sex or int(first.partner_id) != -1 or int(second.partner_id) != -1:
		return false
	first.partner_id = second_id
	second.partner_id = first_id
	save_population()
	return true

func set_daycare(resident_id: int, enrolled: bool) -> bool:
	var resident := _find_resident(resident_id)
	if resident.is_empty() or int(resident.age) >= ADULT_AGE:
		return false
	resident.in_daycare = enrolled
	save_population()
	return true

func get_population_summary() -> Dictionary:
	var summary := {"total": 0, "children": 0, "adults": 0, "elders": 0}
	for person in residents:
		if not person.alive:
			continue
		summary.total += 1
		var age := int(person.age)
		if age < ADULT_AGE:
			summary.children += 1
		elif age < ELDER_AGE:
			summary.adults += 1
		else:
			summary.elders += 1
	return summary

func _advance_one_year() -> void:
	var births: Array[Dictionary] = []
	for person in residents:
		if not person.alive:
			continue
		person.age = int(person.age) + 1
		if int(person.age) >= MAX_AGE or (int(person.age) >= ELDER_AGE and randf() < 0.08):
			person.alive = false
			person.health = 0.0
			resident_died.emit(str(person.name))
			continue
		if int(person.age) >= 20 and int(person.age) <= 40 and person.sex == "female" and int(person.partner_id) != -1:
			if randf() < 0.18:
				births.append(person)
	var current_leader := get_leader()
	if current_leader.is_empty() or int(current_leader.get("age", 0)) >= LEADER_RETIREMENT_AGE:
		elect_new_leader()
	for mother in births:
		var baby_name := "Em bé %d" % _next_id
		add_resident(baby_name, 0, "male" if randf() < 0.5 else "female", "child")
		child_born.emit(baby_name)
	_emit_population()
	save_population()

func get_resident(resident_id: int) -> Dictionary:
	return _find_resident(resident_id)

func _find_resident(resident_id: int) -> Dictionary:
	for person in residents:
		if int(person.id) == resident_id and person.alive:
			return person
	return {}

func _emit_population() -> void:
	var summary := get_population_summary()
	population_changed.emit(summary.total, summary.children, summary.adults, summary.elders)

func save_population() -> void:
	var config := ConfigFile.new()
	config.set_value("tribe", "residents", residents)
	config.set_value("tribe", "next_id", _next_id)
	config.set_value("tribe", "leader_id", leader_id)
	config.save(SAVE_PATH)

func load_population() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Array = config.get_value("tribe", "residents", [])
	residents.clear()
	for person in saved:
		residents.append(person)
	_next_id = int(config.get_value("tribe", "next_id", residents.size() + 1))
	_load_leader_id = int(config.get_value("tribe", "leader_id", -1))
	leader_id = _load_leader_id
