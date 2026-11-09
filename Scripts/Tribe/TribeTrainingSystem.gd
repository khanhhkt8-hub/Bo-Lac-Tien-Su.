extends Node
## Offline warrior training. Training improves resident combat attributes.

signal training_started(resident_id: int)
signal training_completed(resident_id: int, strength: int, stamina: int)

const SAVE_PATH := "user://bo_lac_training.cfg"
const TRAINING_SECONDS := 90.0
const FOOD_COST := 5

var training_queue: Array[Dictionary] = []
var _elapsed: Dictionary = {}

func _ready() -> void:
	_load_state()

func _process(delta: float) -> void:
	for entry in training_queue.duplicate():
		var resident_id := int(entry.resident_id)
		_elapsed[resident_id] = float(_elapsed.get(resident_id, 0.0)) + delta
		if float(_elapsed[resident_id]) >= TRAINING_SECONDS:
			_complete_training(resident_id)

func start_training(resident_id: int) -> bool:
	if not is_instance_valid(TribePopulation):
		return false
	if _is_training(resident_id):
		return false
	var resident := _find_resident(resident_id)
	if resident.is_empty() or int(resident.age) < 18:
		return false
	if int(resident.get("food", FOOD_COST)) < FOOD_COST:
		return false
	resident["food"] = int(resident.get("food", FOOD_COST)) - FOOD_COST
	training_queue.append({"resident_id": resident_id})
	_elapsed[resident_id] = 0.0
	training_started.emit(resident_id)
	_save_state()
	return true

func cancel_training(resident_id: int) -> bool:
	for entry in training_queue:
		if int(entry.resident_id) == resident_id:
			training_queue.erase(entry)
			_elapsed.erase(resident_id)
			_save_state()
			return true
	return false

func get_training_status(resident_id: int) -> Dictionary:
	if not _is_training(resident_id):
		return {"training": false, "remaining": 0.0}
	var remaining := maxf(0.0, TRAINING_SECONDS - float(_elapsed.get(resident_id, 0.0)))
	return {"training": true, "remaining": remaining}

func _complete_training(resident_id: int) -> void:
	var resident := _find_resident(resident_id)
	if not resident.is_empty():
		resident["strength"] = mini(100, int(resident.get("strength", 10)) + 5)
		resident["stamina"] = mini(100, int(resident.get("stamina", 10)) + 5)
		TribePopulation.save_population()
		training_completed.emit(resident_id, int(resident.strength), int(resident.stamina))
	cancel_training(resident_id)

func _find_resident(resident_id: int) -> Dictionary:
	for person in TribePopulation.residents:
		if int(person.id) == resident_id and bool(person.alive):
			return person
	return {}

func _is_training(resident_id: int) -> bool:
	for entry in training_queue:
		if int(entry.resident_id) == resident_id:
			return true
	return false

func _save_state() -> void:
	var config := ConfigFile.new()
	config.set_value("training", "queue", training_queue)
	config.set_value("training", "elapsed", _elapsed)
	config.save(SAVE_PATH)

func _load_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	training_queue.clear()
	for entry in config.get_value("training", "queue", []):
		var resident_id := int(entry.get("resident_id", -1))
		if resident_id >= 0 and not _find_resident(resident_id).is_empty():
			training_queue.append(entry)
	_elapsed = config.get_value("training", "elapsed", {})
