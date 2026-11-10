extends Node2D

signal raid_warning(seconds_left: int)
signal raid_started(raider_count: int)
signal intruder_detected(distance: int)

const BARBARIAN_SCENE: PackedScene = preload("res://Scenes/Barbarian.tscn")

@export var raiders_per_wave: int = 3
@export var spawn_distance: float = 460.0
@export var max_barbarians_alive: int = 9
@export var chief_every_nights: int = 5

var raid_started_this_night: bool = false
var nights_survived: int = 0
var warning_time_left: float = -1.0
var last_warning_second: int = -1
var _intrusion_scan_timer := 0.0
var _alerted_intruders: Dictionary = {}

func _process(_delta: float) -> void:
	_scan_for_intruders(_delta)
	var cycles := get_tree().get_nodes_in_group("day_night_cycle")
	if cycles.is_empty():
		return
	var cycle := cycles[0] as DayNightCycle
	if not is_instance_valid(cycle):
		return
	if not cycle.is_night:
		raid_started_this_night = false
		warning_time_left = -1.0
		last_warning_second = -1
		return
	if raid_started_this_night:
		return
	if warning_time_left < 0.0:
		warning_time_left = 12.0
		last_warning_second = 12
		raid_warning.emit(12)
		return
	warning_time_left = maxf(0.0, warning_time_left - _delta)
	var seconds_left := ceili(warning_time_left)
	if seconds_left != last_warning_second and seconds_left > 0:
		last_warning_second = seconds_left
		raid_warning.emit(seconds_left)
	if warning_time_left <= 0.0:
		raid_started_this_night = true
		nights_survived += 1
		_start_raid()

func _start_raid() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var army: Dictionary = TribeArmySystem.get_army_summary()
	var defended := int(army.power / 25)
	var alive := get_tree().get_nodes_in_group("barbarians").size()
	var available := maxi(0, max_barbarians_alive - alive)
	var count := mini(maxi(0, raiders_per_wave - defended), available)
	for i in range(count):
		_spawn_raider(player.global_position, false)
	if count > 0:
		_attempt_resource_raid()
	if chief_every_nights > 0 and nights_survived % chief_every_nights == 0:
		_spawn_raider(player.global_position, true)
	raid_started.emit(count + (1 if chief_every_nights > 0 and nights_survived % chief_every_nights == 0 else 0))

func _spawn_raider(center: Vector2, chief: bool) -> void:
	var angle := randf() * TAU
	var offset := Vector2.RIGHT.rotated(angle) * (spawn_distance * (1.15 if chief else 1.0))
	var raider := BARBARIAN_SCENE.instantiate() as Node2D
	raider.set("is_chief", chief)
	get_parent().add_child(raider)
	raider.global_position = center + offset

func _attempt_resource_raid() -> void:
	var candidates: Array[String] = []
	var stock: Dictionary = TribeJobSystem.stockpile
	for resource_id in ["meat", "berries", "food", "tools"]:
		if int(stock.get(resource_id, 0)) > 0:
			candidates.append(resource_id)
	if candidates.is_empty():
		return
	var target: String = candidates[randi_range(0, candidates.size() - 1)]
	var stolen := TribeJobSystem.raid_stockpile(target, randi_range(1, 3))
	if stolen > 0:
		print("Man rợ đột kích và cướp ", stolen, " ", target, " khỏi kho bộ lạc!")


func _scan_for_intruders(delta: float) -> void:
	_intrusion_scan_timer -= delta
	if _intrusion_scan_timer > 0.0:
		return
	_intrusion_scan_timer = 0.5
	var control := get_parent().get_node_or_null("TribeControlSystem")
	var center := Vector2.ZERO
	if control != null and bool(control.get("has_rally_point")):
		center = control.get("rally_point")
	else:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(player):
			return
		center = player.global_position
	var active_ids: Dictionary = {}
	for intruder in get_tree().get_nodes_in_group("barbarians"):
		if not is_instance_valid(intruder) or not intruder is Node2D:
			continue
		var enemy := intruder as Node2D
		var enemy_id := enemy.get_instance_id()
		active_ids[enemy_id] = true
		var distance := enemy.global_position.distance_to(center)
		if distance <= 340.0 and not _alerted_intruders.has(enemy_id):
			_alerted_intruders[enemy_id] = true
			intruder_detected.emit(roundi(distance))
			if control != null and control.has_method("dispatch_nearest_defenders"):
				control.call("dispatch_nearest_defenders", enemy, 3)
	for alerted_id in _alerted_intruders.keys():
		if not active_ids.has(alerted_id):
			_alerted_intruders.erase(alerted_id)
