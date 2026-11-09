extends Node2D
## Creates one hostile outpost in each discovered biome. Cleared camps stay cleared offline.

const BARBARIAN_SCENE: PackedScene = preload("res://Scenes/Barbarian.tscn")
const SAVE_PATH := "user://bo_lac_camps.cfg"
const CAMP_OFFSETS := {
	"heartland": Vector2(310.0, 250.0),
	"primeval_forest": Vector2(-260.0, 210.0),
	"grassland": Vector2(280.0, -230.0),
	"swampland": Vector2(-280.0, -220.0),
	"cavern": Vector2(260.0, 240.0),
	"frostlands": Vector2(0.0, 300.0)
}
const CAMP_NAMES := {
	"heartland": "Trại tiền tiêu",
	"primeval_forest": "Trại thợ săn man rợ",
	"grassland": "Trại kỵ thú",
	"swampland": "Trại đầm lầy",
	"cavern": "Pháo đài hang đá",
	"frostlands": "Trại băng giá"
}

var cleared_camps: Dictionary = {}
var active_region := ""
var active_camp_position := Vector2.ZERO
var active_camp_name := ""
var active := false
var _check_timer := 0.0

func _ready() -> void:
	_load_progress()
	RegionSystem.region_changed.connect(_on_region_changed)

func _process(delta: float) -> void:
	if not active:
		return
	_check_timer += delta
	if _check_timer < 1.0:
		return
	_check_timer = 0.0
	var remaining := 0
	for enemy in get_tree().get_nodes_in_group("camp_enemies"):
		if is_instance_valid(enemy) and enemy.get_meta("camp_region", "") == active_region:
			remaining += 1
	if remaining == 0:
		_complete_camp()

func _on_region_changed(region_id: String, _data: Dictionary) -> void:
	if region_id == active_region:
		return
	_clear_active_camp()
	active_region = region_id
	if region_id.is_empty() or bool(cleared_camps.get(region_id, false)):
		queue_redraw()
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var offset: Vector2 = CAMP_OFFSETS.get(region_id, Vector2(250.0, 250.0))
	var region_data: Dictionary = RegionSystem.get_region_data(region_id)
	var center: Vector2 = region_data.get("center", player.global_position)
	var radius := float(region_data.get("radius", 600.0))
	var candidate := player.global_position + offset.normalized() * 300.0
	if candidate.distance_to(center) > radius * 0.72:
		candidate = center + candidate.direction_to(center) * radius * 0.65
	active_camp_position = candidate
	active_camp_name = str(CAMP_NAMES.get(region_id, "Trại man rợ"))
	_spawn_camp(region_id)
	queue_redraw()

func _spawn_camp(region_id: String) -> void:
	active = true
	var guards := 2 + int(RegionSystem.get_region_data(region_id).get("danger", 1)) / 2
	for i in range(guards + 1):
		var barbarian := BARBARIAN_SCENE.instantiate() as BarbarianAI
		barbarian.is_chief = i == guards
		add_child(barbarian)
		barbarian.global_position = active_camp_position + Vector2.RIGHT.rotated(TAU * float(i) / float(guards + 1)) * (54.0 + float(i % 2) * 24.0)
		barbarian.add_to_group("camp_enemies")
		barbarian.set_meta("camp_region", region_id)

func _complete_camp() -> void:
	active = false
	cleared_camps[active_region] = true
	_save_progress()
	TribeJobSystem.add_to_stockpile("food", 15)
	TribeJobSystem.add_to_stockpile("tools", 10)
	TribeJobSystem.add_to_stockpile("warrior_power", 5)
	print("Đã chiếm trại: ", active_camp_name, ". Thưởng 15 lương thực, 10 dụng cụ, 5 chiến lực.")
	queue_redraw()

func _clear_active_camp() -> void:
	for enemy in get_tree().get_nodes_in_group("camp_enemies"):
		if is_instance_valid(enemy) and enemy.get_meta("camp_region", "") == active_region:
			enemy.queue_free()
	active = false

func _draw() -> void:
	if active and not active_region.is_empty():
		draw_circle(to_local(active_camp_position), 72.0, Color(0.55, 0.12, 0.08, 0.22))
		draw_arc(to_local(active_camp_position), 72.0, 0.0, TAU, 36, Color("#d7a34b"), 3.0)
		draw_circle(to_local(active_camp_position), 18.0, Color("#76513b"))
		draw_line(to_local(active_camp_position + Vector2(-12, -12)), to_local(active_camp_position + Vector2(12, 12)), Color("#d7a34b"), 3.0)
		draw_line(to_local(active_camp_position + Vector2(12, -12)), to_local(active_camp_position + Vector2(-12, 12)), Color("#d7a34b"), 3.0)
		draw_string(ThemeDB.fallback_font, to_local(active_camp_position + Vector2(-68, -88)), active_camp_name, HORIZONTAL_ALIGNMENT_LEFT, 180.0, 16, Color("#fff0c7"))

func _save_progress() -> void:
	var config := ConfigFile.new()
	config.set_value("camps", "cleared", cleared_camps)
	config.save(SAVE_PATH)

func _load_progress() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Dictionary = config.get_value("camps", "cleared", {})
	for region_id in saved:
		if CAMP_OFFSETS.has(str(region_id)) and bool(saved[region_id]):
			cleared_camps[str(region_id)] = true
