extends Node2D

const BARBARIAN_SCENE: PackedScene = preload("res://Scenes/Barbarian.tscn")

@export var raiders_per_wave: int = 3
@export var spawn_distance: float = 460.0
@export var max_barbarians_alive: int = 9
@export var chief_every_nights: int = 5

var raid_started_this_night: bool = false
var nights_survived: int = 0

func _process(_delta: float) -> void:
	var cycles := get_tree().get_nodes_in_group("day_night_cycle")
	if cycles.is_empty():
		return
	var cycle := cycles[0] as DayNightCycle
	if not is_instance_valid(cycle):
		return
	if not cycle.is_night:
		raid_started_this_night = false
		return
	if raid_started_this_night:
		return
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
