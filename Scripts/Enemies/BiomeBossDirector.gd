extends Node2D
## One persistent apex predator per biome. Defeated bosses stay defeated offline.

const ANIMAL_SCENE: PackedScene = preload("res://Scenes/PrehistoricAnimal.tscn")
const SAVE_PATH := "user://bo_lac_bosses.cfg"

const BOSS_DATA := {
	"heartland": {"name": "MAMMOTH ALPHA", "species": "mammoth", "health": 620.0, "damage": 34.0, "speed": 64.0, "reward": "ore", "amount": 8, "offset": Vector2(-390.0, -300.0)},
	"primeval_forest": {"name": "CHÚA HỔ RĂNG KIẾM", "species": "saber_tooth", "health": 420.0, "damage": 27.0, "speed": 150.0, "reward": "hide", "amount": 18, "offset": Vector2(390.0, -300.0)},
	"grassland": {"name": "VOI MA MÚT ĐẦU ĐÀN", "species": "mammoth", "health": 760.0, "damage": 42.0, "speed": 68.0, "reward": "bone", "amount": 20, "offset": Vector2(-390.0, 300.0)},
	"swampland": {"name": "GẤU CHÚA ĐẦM LẦY", "species": "cave_bear", "health": 560.0, "damage": 32.0, "speed": 88.0, "reward": "herbs", "amount": 16, "offset": Vector2(390.0, 300.0)},
	"cavern": {"name": "CỰ THÚ HANG ĐÁ", "species": "cave_bear", "health": 700.0, "damage": 39.0, "speed": 92.0, "reward": "ore", "amount": 18, "offset": Vector2(-390.0, -300.0)},
	"frostlands": {"name": "GẤU TUYẾT CỔ ĐẠI", "species": "cave_bear", "health": 680.0, "damage": 38.0, "speed": 94.0, "reward": "ice", "amount": 20, "offset": Vector2(390.0, 300.0)}
}

var defeated_bosses: Dictionary = {}
var active_region := ""
var active_boss: PrehistoricAnimal
var active_boss_name := ""
var active_boss_position := Vector2.ZERO
var _boss_cleanup := false

func _ready() -> void:
	_load_progress()
	RegionSystem.region_changed.connect(_on_region_changed)

func _on_region_changed(region_id: String, _region_data: Dictionary) -> void:
	if region_id == active_region:
		return
	_remove_active_boss()
	active_region = region_id
	if region_id.is_empty() or not BOSS_DATA.has(region_id) or bool(defeated_bosses.get(region_id, false)):
		queue_redraw()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var data: Dictionary = BOSS_DATA[region_id]
	var offset: Vector2 = data.offset
	active_boss_position = player.global_position + offset
	var center: Vector2 = RegionSystem.get_region_data(region_id).get("center", player.global_position)
	var radius := float(RegionSystem.get_region_data(region_id).get("radius", 600.0))
	if active_boss_position.distance_to(center) > radius * 0.82:
		active_boss_position = center + (active_boss_position - center).normalized() * radius * 0.72
	_spawn_boss(region_id, data)
	queue_redraw()

func _spawn_boss(region_id: String, data: Dictionary) -> void:
	active_boss = ANIMAL_SCENE.instantiate() as PrehistoricAnimal
	active_boss.species = str(data.species)
	active_boss.passive_until_attacked = true
	add_child(active_boss)
	active_boss.global_position = active_boss_position
	active_boss.enemy_name = str(data.name)
	active_boss.max_health = float(data.health)
	active_boss.health = active_boss.max_health
	active_boss.attack_damage = float(data.damage)
	active_boss.move_speed = float(data.speed)
	active_boss.detection_range = 340.0
	active_boss.attack_range = 38.0
	active_boss.scale = Vector2(1.65, 1.65)
	active_boss.add_to_group("biome_boss")
	active_boss.set_meta("boss_region", region_id)
	active_boss.tree_exiting.connect(_on_boss_tree_exiting.bind(region_id, active_boss))
	active_boss_name = str(data.name)
	print("Boss khu vực xuất hiện: ", active_boss_name)

func _on_boss_tree_exiting(region_id: String, boss: PrehistoricAnimal) -> void:
	if _boss_cleanup or (is_instance_valid(boss) and bool(boss.get_meta("boss_cleanup", false))):
		return
	if is_instance_valid(boss) and boss.health <= 0.0:
		defeated_bosses[region_id] = true
		_save_progress()
		var data: Dictionary = BOSS_DATA[region_id]
		TribeJobSystem.add_to_stockpile(str(data.reward), int(data.amount))
		TribeJobSystem.add_to_stockpile("warrior_power", 12)
		print("Đã hạ boss ", data.name, "! Nhận ", data.amount, " ", data.reward, " và 12 chiến lực.")
	active_boss = null
	queue_redraw()

func _remove_active_boss() -> void:
	if is_instance_valid(active_boss):
		_boss_cleanup = true
		active_boss.set_meta("boss_cleanup", true)
		active_boss.queue_free()
		active_boss = null
		_boss_cleanup = false

func _draw() -> void:
	if is_instance_valid(active_boss):
		var point := to_local(active_boss_position)
		draw_arc(point, 42.0, 0.0, TAU, 40, Color("#e3a63b"), 3.0)
		draw_string(ThemeDB.fallback_font, point + Vector2(-100.0, -58.0), active_boss_name, HORIZONTAL_ALIGNMENT_LEFT, 220.0, 17, Color("#ffdb79"))

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("bosses", "defeated", defeated_bosses)
	config.save(SAVE_PATH)

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Dictionary = config.get_value("bosses", "defeated", {})
	for region_id in saved:
		if BOSS_DATA.has(str(region_id)) and bool(saved[region_id]):
			defeated_bosses[str(region_id)] = true
