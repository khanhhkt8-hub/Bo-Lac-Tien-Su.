extends Node
## Data-driven exploration regions for the prehistoric world.

signal region_changed(region_id: String, region_data: Dictionary)
signal region_discovered(region_id: String, region_data: Dictionary)

const SAVE_PATH := "user://bo_lac_regions.cfg"
const CHECK_INTERVAL := 0.35

const REGIONS := {
	"heartland": {
		"name": "ĐỒNG BẰNG BỘ LẠC",
		"description": "Vùng khởi đầu tương đối an toàn, thích hợp săn bắt và thu thập.",
		"center": Vector2(0, 0),
		"radius": 520.0,
		"danger": 1,
		"climate": "Ôn hòa",
		"resources": ["wood", "stone", "food", "water"],
		"wildlife": ["wolf"],
		"hazard": "Thú săn mồi thưa thớt"
	},
	"primeval_forest": {
		"name": "RỪNG NGUYÊN SINH",
		"description": "Rừng rậm nhiều gỗ, quả dại và thú săn mồi.",
		"center": Vector2(-1100, -900),
		"radius": 650.0,
		"danger": 3,
		"climate": "Ẩm và mát",
		"resources": ["wood", "berries", "hide", "herbs"],
		"wildlife": ["wolf", "saber_tooth"],
		"hazard": "Thú săn mồi phục kích trong tán rừng"
	},
	"grassland": {
		"name": "ĐỒNG CỎ MÊNH MÔNG",
		"description": "Đồng cỏ rộng, dễ quan sát đàn thú và tìm thức ăn.",
		"center": Vector2(1100, -900),
		"radius": 650.0,
		"danger": 2,
		"climate": "Nắng và nhiều gió",
		"resources": ["food", "hide", "bone", "flint"],
		"wildlife": ["mammoth", "wolf"],
		"hazard": "Đàn thú lớn có thể giẫm đạp"
	},
	"swampland": {
		"name": "ĐẦM LẦY SƯƠNG ĐỘC",
		"description": "Đầm nước sâu, nhiều thảo dược nhưng địa hình nguy hiểm.",
		"center": Vector2(-1100, 1000),
		"radius": 650.0,
		"danger": 4,
		"climate": "Ẩm nóng",
		"resources": ["water", "herbs", "berries", "reeds"],
		"wildlife": ["cave_bear", "wolf"],
		"hazard": "Bùn lún và côn trùng độc"
	},
	"cavern": {
		"name": "HANG ĐỘNG CỔ XƯA",
		"description": "Hang tối chứa đá, đá lửa và xương cổ đại.",
		"center": Vector2(1100, 1000),
		"radius": 650.0,
		"danger": 5,
		"climate": "Lạnh và thiếu ánh sáng",
		"resources": ["stone", "flint", "bone", "ore"],
		"wildlife": ["cave_bear", "saber_tooth"],
		"hazard": "Thú dữ trong bóng tối và đường hang hiểm trở"
	},
	"frostlands": {
		"name": "MIỀN BĂNG TUYẾT",
		"description": "Vùng đất lạnh giá, khắc nghiệt nhưng giàu da và xương thú.",
		"center": Vector2(0, -1800),
		"radius": 650.0,
		"danger": 5,
		"climate": "Băng giá",
		"resources": ["ice", "hide", "bone", "meat"],
		"wildlife": ["mammoth", "cave_bear"],
		"hazard": "Hạ thân nhiệt và thú khổng lồ"
	}
}

var discovered: Dictionary = {"heartland": true}
var current_region_id: String = ""
var _check_timer: float = 0.0

func _ready() -> void:
	load_discoveries()

func _process(delta: float) -> void:
	_check_timer += delta
	if _check_timer < CHECK_INTERVAL:
		return
	_check_timer = 0.0
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var region_id := get_region_id_at(player.global_position)
	if region_id == current_region_id:
		return
	current_region_id = region_id
	if region_id.is_empty():
		region_changed.emit("", {})
		return
	var data: Dictionary = REGIONS[region_id].duplicate(true)
	if not bool(discovered.get(region_id, false)):
		discovered[region_id] = true
		save_discoveries()
		region_discovered.emit(region_id, data)
	region_changed.emit(region_id, data)

func get_region_id_at(world_position: Vector2) -> String:
	var closest_id := ""
	var closest_distance := INF
	for region_id in REGIONS:
		var data: Dictionary = REGIONS[region_id]
		var distance: float = world_position.distance_to(data.center)
		if distance <= float(data.radius) and distance < closest_distance:
			closest_id = str(region_id)
			closest_distance = distance
	return closest_id

func get_region_data(region_id: String) -> Dictionary:
	if not REGIONS.has(region_id):
		return {}
	return REGIONS[region_id].duplicate(true)

func get_discovery_summary() -> Dictionary:
	return {
		"discovered": discovered.size(),
		"total": REGIONS.size(),
		"regions": discovered.keys()
	}

func save_discoveries() -> void:
	var config := ConfigFile.new()
	config.set_value("exploration", "discovered", discovered)
	config.save(SAVE_PATH)

func load_discoveries() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Dictionary = config.get_value("exploration", "discovered", {"heartland": true})
	for region_id in saved:
		if REGIONS.has(str(region_id)) and bool(saved[region_id]):
			discovered[str(region_id)] = true
