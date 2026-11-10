extends Node
## Scout missions reveal nearby world information and persist field reports offline.

signal status_changed(message: String)

const SAVE_PATH := "user://bo_lac_scout_reports.cfg"
const REPORT_LIMIT := 20
const ARRIVAL_RADIUS := 34.0

var missions: Array[Dictionary] = []
var reports: Array[Dictionary] = []
var _scan_timer := 0.0

func _ready() -> void:
	_load_reports()

func _process(delta: float) -> void:
	_scan_timer += delta
	if _scan_timer < 0.5:
		return
	_scan_timer = 0.0
	_update_missions()

func dispatch_scouts(resident_ids: Array, destination: Vector2, unit_registry: Dictionary) -> String:
	var dispatched := 0
	for resident_id_value in resident_ids:
		var resident_id := int(resident_id_value)
		if not unit_registry.has(resident_id):
			continue
		var unit := unit_registry[resident_id] as Node2D
		if not is_instance_valid(unit) or str(unit.get("role")) != "scout" or int(unit.get("resident_age")) < 18:
			continue
		var slot := Vector2(float(dispatched % 3) * 26.0, float(int(dispatched / 3)) * 26.0)
		var target := destination + slot
		if unit.has_method("issue_move_order"):
			unit.call("issue_move_order", target)
			missions.append({"resident_id": resident_id, "target": target, "started_at": Time.get_unix_time_from_system()})
			dispatched += 1
	if dispatched == 0:
		var warning := "Hãy chọn ít nhất một trinh sát trưởng thành trước khi giao nhiệm vụ."
		status_changed.emit(warning)
		return warning
	_save_reports()
	var message := "Đã cử %d trinh sát đến khu vực được đánh dấu. Báo cáo sẽ xuất hiện khi đội đến nơi." % dispatched
	status_changed.emit(message)
	return message

func _update_missions() -> void:
	var completed: Array[Dictionary] = []
	for mission in missions:
		var resident_id := int(mission.get("resident_id", -1))
		var target: Vector2 = mission.get("target", Vector2.ZERO)
		var unit := _find_unit(resident_id)
		if unit == null:
			completed.append(mission)
			continue
		if unit.global_position.distance_to(target) <= ARRIVAL_RADIUS and not bool(unit.get("has_move_order")):
			completed.append(mission)
	for mission in completed:
		missions.erase(mission)
		var target: Vector2 = mission.get("target", Vector2.ZERO)
		_create_report(target, int(mission.get("resident_id", -1)))
		status_changed.emit("Trinh sát đã đến nơi. Báo cáo mới: " + str(reports[0].get("region", "khu vực mới")) + ".")
	if not completed.is_empty():
		_save_reports()

func _find_unit(resident_id: int) -> Node2D:
	for unit in get_tree().get_nodes_in_group("tribe_units"):
		if is_instance_valid(unit) and int(unit.get("resident_id")) == resident_id:
			return unit as Node2D
	return null

func _create_report(center: Vector2, resident_id: int) -> void:
	var resources: Array[String] = []
	var wildlife: Array[String] = []
	var enemies: Array[String] = []
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		if (node as Node2D).global_position.distance_to(center) <= 280.0:
			resources.append("%s (%d)" % [str(node.get("resource_type")), int(node.get("amount_available"))])
	for node in get_tree().get_nodes_in_group("animals"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		if (node as Node2D).global_position.distance_to(center) <= 280.0:
			var species := str(node.get("species"))
	\t\tif not species.is_empty():
	\t\t\twildlife.append(species)
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		if (node as Node2D).global_position.distance_to(center) <= 320.0:
			enemies.append(str(node.get("enemy_name")) if node.get("enemy_name") != null else "Kẻ địch")
	var region_name := "Vùng hoang dã chưa xác định"
	if RegionSystem != null:
		var region_data: Dictionary = RegionSystem.get_region_at_position(center)
		if not region_data.is_empty():
			region_name = str(region_data.get("name", region_name))
	var report := {
		"time": Time.get_unix_time_from_system(),
		"resident_id": resident_id,
		"x": roundi(center.x),
		"y": roundi(center.y),
		"region": region_name,
		"resources": resources,
		"wildlife": wildlife,
		"enemies": enemies
	}
	reports.push_front(report)
	while reports.size() > REPORT_LIMIT:
		reports.pop_back()

func get_latest_report_text() -> String:
	if reports.is_empty():
		return "Chưa có báo cáo. Hãy chọn TRINH SÁT, chọn đội và chạm vào vùng muốn khám phá."
	var report: Dictionary = reports[0]
	var resources: Array = report.get("resources", [])
	var wildlife: Array = report.get("wildlife", [])
	var enemies: Array = report.get("enemies", [])
	return "BÁO CÁO TRINH SÁT – %s\nTọa độ: %d, %d\nTài nguyên: %s\nThú hoang: %s\nKẻ địch: %s" % [
		str(report.get("region", "Chưa rõ")),
		int(report.get("x", 0)),
		int(report.get("y", 0)),
		", ".join(PackedStringArray(resources)) if not resources.is_empty() else "Chưa phát hiện",
		", ".join(PackedStringArray(wildlife)) if not wildlife.is_empty() else "Chưa phát hiện",
		", ".join(PackedStringArray(enemies)) if not enemies.is_empty() else "Chưa phát hiện"
	]

func get_mission_count() -> int:
	return missions.size()

func _save_reports() -> void:
	var config := ConfigFile.new()
	config.set_value("scouting", "reports", reports)
	config.save(SAVE_PATH)

func _load_reports() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		reports = config.get_value("scouting", "reports", [])
