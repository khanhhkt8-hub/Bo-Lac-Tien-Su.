extends Node2D
## RTS-style control for all tribe residents.

const UNIT_SCRIPT = preload("res://Scripts/Tribe/TribeUnit.gd")
const RALLY_SAVE_PATH := "user://bo_lac_rally_flag.cfg"
var units: Dictionary = {}
var selected_ids: Array[int] = []
var move_mode := false
var rally_mode := false
var patrol_mode := false
var scout_mode := false
var _patrol_points: Array[Vector2] = []
var selection_area_mode := false
var _pointer_down := false
var _drag_selecting := false
var _press_screen := Vector2.ZERO
var _selection_start_world := Vector2.ZERO
var _selection_end_world := Vector2.ZERO
var rally_point := Vector2.ZERO
var has_rally_point := false
var _sync_timer := 0.0
var _spawn_center := Vector2.ZERO

func _ready() -> void:
	var player := get_parent().get_node_or_null("Player")
	if player != null:
		_spawn_center = player.global_position
	_load_rally_point()
	_sync_units()
	if TribePopulation != null and not TribePopulation.population_changed.is_connected(_on_population_changed):
		TribePopulation.population_changed.connect(_on_population_changed)

func _process(delta: float) -> void:
	_sync_timer += delta
	if _sync_timer >= 2.0:
		_sync_timer = 0.0
		_sync_units()

func _on_population_changed(_total: int, _children: int, _adults: int, _elders: int) -> void:
	_sync_units()

func _sync_units() -> void:
	if TribePopulation == null:
		return
	var alive_ids: Dictionary = {}
	for person in TribePopulation.residents:
		if bool(person.get("alive", true)):
			alive_ids[int(person.get("id", -1))] = true
	for id in units.keys():
		if not alive_ids.has(int(id)):
			if is_instance_valid(units[id]):
				(units[id] as TribeUnit).queue_free()
			units.erase(id)
			selected_ids.erase(int(id))
	for person in TribePopulation.residents:
		if not bool(person.get("alive", true)):
			continue
		var id := int(person.get("id", -1))
		if id < 0:
			continue
		if units.has(id):
			if is_instance_valid(units[id]):
				(units[id] as TribeUnit).role = str(person.get("job", person.get("role", "villager")))
				(units[id] as TribeUnit).move_speed = 132.0 if (units[id] as TribeUnit).role == "scout" else 105.0
				(units[id] as TribeUnit).queue_redraw()
			continue
		var unit := UNIT_SCRIPT.new() as TribeUnit
		add_child(unit)
		unit.setup(person)
		var offset := Vector2(float((units.size() % 4) - 1) * 34.0, float(int(units.size() / 4)) * 34.0 + 70.0)
		unit.global_position = _spawn_center + offset
		units[id] = unit

func select_all() -> int:
	selected_ids.clear()
	for id in units:
		var unit: TribeUnit = units[id]
		if is_instance_valid(unit):
			unit.set_selected(true)
			selected_ids.append(int(id))
	return selected_ids.size()

func select_role(role_id: String) -> int:
	clear_selection()
	for id in units:
		var unit: TribeUnit = units[id]
		if is_instance_valid(unit) and unit.role == role_id:
			unit.set_selected(true)
			selected_ids.append(int(id))
	return selected_ids.size()

func select_role_additive(role_id: String) -> int:
	for id in units:
		var unit: TribeUnit = units[id]
		if is_instance_valid(unit) and unit.role == role_id and not selected_ids.has(int(id)):
			unit.set_selected(true)
			selected_ids.append(int(id))
	return selected_ids.size()

func select_support_roles(additive: bool = false) -> int:
	if not additive:
		clear_selection()
	for id in units:
		var unit: TribeUnit = units[id]
		if not is_instance_valid(unit):
			continue
		if unit.role in ["gatherer", "farmer", "crafter"] and not selected_ids.has(int(id)):
			unit.set_selected(true)
			selected_ids.append(int(id))
	return selected_ids.size()

func select_adult_role(role_id: String) -> int:
	clear_selection()
	for id in units:
		var unit: TribeUnit = units[id]
		if is_instance_valid(unit) and unit.role == role_id and unit.resident_age >= 18:
			unit.set_selected(true)
			selected_ids.append(int(id))
	return selected_ids.size()

func clear_selection() -> void:
	for id in selected_ids:
		if units.has(id) and is_instance_valid(units[id]):
			(units[id] as TribeUnit).set_selected(false)
	selected_ids.clear()

func set_move_mode(enabled: bool) -> void:
	move_mode = enabled
	scout_mode = false
	rally_mode = false
	patrol_mode = false
	_patrol_points.clear()
	selection_area_mode = false

func set_selection_area_mode(enabled: bool) -> void:
	selection_area_mode = enabled
	scout_mode = false
	move_mode = false
	rally_mode = false
	patrol_mode = false
	_patrol_points.clear()
	_pointer_down = false
	_drag_selecting = false
	queue_redraw()


func set_rally_mode(enabled: bool) -> void:
	rally_mode = enabled
	scout_mode = false
	move_mode = false
	patrol_mode = false
	_patrol_points.clear()
	selection_area_mode = false
	_pointer_down = false
	_drag_selecting = false
	queue_redraw()

func set_scout_mode(enabled: bool) -> void:
	scout_mode = enabled
	move_mode = false
	rally_mode = false
	patrol_mode = false
	selection_area_mode = false
	_pointer_down = false
	_drag_selecting = false

func set_patrol_mode(enabled: bool) -> void:
	patrol_mode = enabled
	scout_mode = false
	_patrol_points.clear()
	move_mode = false
	rally_mode = false
	selection_area_mode = false
	_pointer_down = false
	_drag_selecting = false
	queue_redraw()

func order_selected_patrol(points: Array[Vector2]) -> int:
	if points.size() < 2:
		return 0
	var count := 0
	for id in selected_ids:
		if not units.has(id) or not is_instance_valid(units[id]):
			continue
		var unit: TribeUnit = units[id]
		if unit.resident_age < 18:
			continue
		var offset := Vector2(float(count % 4) * 16.0, float(int(count / 4)) * 16.0)
		var route: Array[Vector2] = []
		for point in points:
			route.append(point + offset)
		unit.set_patrol_route(route)
		count += 1
	return count

func set_rally_point(destination: Vector2) -> void:
	rally_point = destination
	has_rally_point = true
	_save_rally_point()
	queue_redraw()

func _save_rally_point() -> void:
	var config := ConfigFile.new()
	config.set_value("rally", "position", rally_point)
	config.set_value("rally", "placed", has_rally_point)
	config.save(RALLY_SAVE_PATH)

func _load_rally_point() -> void:
	var config := ConfigFile.new()
	if config.load(RALLY_SAVE_PATH) != OK:
		return
	has_rally_point = bool(config.get_value("rally", "placed", false))
	rally_point = config.get_value("rally", "position", Vector2.ZERO)
	queue_redraw()

func rally_all_to_flag() -> int:
	if not has_rally_point:
		return 0
	select_all()
	var count := 0
	for id in selected_ids:
		if not units.has(id) or not is_instance_valid(units[id]):
			continue
		var unit: TribeUnit = units[id]
		var column := count % 5
		var row := int(count / 5)
		var slot := Vector2((column - 2) * 34.0, row * 34.0 + 45.0)
		unit.combat_order_active = false
		unit.issue_move_order(rally_point + slot)
		count += 1
	return count

func _draw() -> void:
	if _patrol_points.size() > 0:
		for i in range(_patrol_points.size()):
			var point := to_local(_patrol_points[i])
			draw_circle(point, 13.0, Color("#f0c75e"))
			draw_arc(point, 19.0, 0.0, TAU, 24, Color("#f0c75e"), 2.0)
			if i > 0:
				draw_line(to_local(_patrol_points[i - 1]), point, Color("#f0c75e"), 3.0)
	if _drag_selecting:
		var rect := Rect2(to_local(_selection_start_world), to_local(_selection_end_world)).abs()
		draw_rect(rect, Color(0.25, 0.75, 1.0, 0.16), true)
		draw_rect(rect, Color(0.45, 0.85, 1.0, 0.95), false, 2.0)
	if not has_rally_point:
		return
	var flag_base := to_local(rally_point)
	draw_circle(flag_base, 58.0, Color(0.95, 0.72, 0.18, 0.10))
	draw_arc(flag_base, 58.0, 0.0, TAU, 48, Color("#e7c45a"), 2.0)
	draw_line(flag_base + Vector2(0, 4), flag_base + Vector2(0, -76), Color("#e8dfc8"), 4.0)
	var flag := PackedVector2Array([
		flag_base + Vector2(2, -74),
		flag_base + Vector2(44, -62),
		flag_base + Vector2(2, -48)
	])
	draw_colored_polygon(flag, Color("#d84b3f"))

func order_selected_move(destination: Vector2) -> int:
	var count := 0
	for id in selected_ids:
		if not units.has(id) or not is_instance_valid(units[id]):
			continue
		var unit: TribeUnit = units[id]
		var slot := Vector2(float(count % 4) * 26.0, float(int(count / 4)) * 26.0)
		unit.issue_move_order(destination + slot)
		count += 1
	move_mode = false
	return count

func order_all_follow_player() -> int:
	if selected_ids.is_empty():
		select_all()
	var player := get_parent().get_node_or_null("Player")
	if player == null:
		return 0
	var count := 0
	for id in selected_ids:
		if units.has(id) and is_instance_valid(units[id]):
			(units[id] as TribeUnit).issue_move_order(player.global_position + Vector2(randf_range(-90.0, 90.0), randf_range(70.0, 140.0)))
			count += 1
	return count

func order_selected_hold_position() -> int:
	var count := 0
	for id in selected_ids:
		if not units.has(id) or not is_instance_valid(units[id]):
			continue
		var unit: TribeUnit = units[id]
		unit.set_hold_position()
		if unit.hold_position_active:
			count += 1
	return count

func order_all_attack() -> int:
	if selected_ids.is_empty():
		select_all()
	var count := 0
	for id in selected_ids:
		if not units.has(id) or not is_instance_valid(units[id]):
			continue
		var unit: TribeUnit = units[id]
		unit.combat_order_active = unit.resident_age >= 18
		unit.hold_position_active = false
		unit.hold_target = null
		unit.patrol_active = false
		unit.patrol_points.clear()
		unit.patrol_target = null
		unit.has_move_order = false
		unit.combat_target = null
		if unit.combat_order_active:
			count += 1
	return count


func dispatch_nearest_defenders(enemy: Node2D, defender_limit: int = 3) -> int:
	if not is_instance_valid(enemy) or defender_limit <= 0:
		return 0
	var candidates: Array[TribeUnit] = []
	for id in units:
		var unit := units[id] as TribeUnit
		if not is_instance_valid(unit) or unit.resident_age < 18:
			continue
		if unit.role != "warrior" and unit.role != "night_guard":
			continue
		candidates.append(unit)
	candidates.sort_custom(func(a: TribeUnit, b: TribeUnit) -> bool:
		return a.global_position.distance_squared_to(enemy.global_position) < b.global_position.distance_squared_to(enemy.global_position)
	)
	var dispatched := 0
	for unit in candidates:
		if dispatched >= defender_limit:
			break
		if unit.global_position.distance_to(enemy.global_position) > 720.0:
			continue
		unit.has_move_order = false
		unit.combat_order_active = true
		unit.combat_target = enemy
		unit.hold_position_active = false
		unit.hold_target = null
		unit.patrol_active = false
		unit.patrol_target = null
		unit.patrol_points.clear()
		unit.gathering_target = null
		unit.hunting_target = null
		dispatched += 1
	return dispatched

func capture_nearest_prisoner() -> String:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return "Không tìm thấy vị trí người chơi."
	var nearest: Node2D
	var nearest_distance := 120.0
	for candidate in get_tree().get_nodes_in_group("surrendered_barbarians"):
		if not is_instance_valid(candidate) or candidate.is_queued_for_deletion() or not candidate is Node2D:
			continue
		var distance := player.global_position.distance_to((candidate as Node2D).global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate as Node2D
	if not is_instance_valid(nearest):
		return "Không có tù binh đầu hàng trong phạm vi 100."
	var prisoner_name := "Tù binh man rợ %d" % randi_range(10, 99)
	var new_id := TribePopulation.recruit_migrant(prisoner_name, 20, "male", "villager")
	if new_id < 0:
		return "Không thể tiếp nhận tù binh."
	nearest.remove_from_group("surrendered_barbarians")
	nearest.queue_free()
	return "Đã thu phục %s. Hãy phân công nghề tại bảng bộ lạc."

func get_selected_count() -> int:
	return selected_ids.size()

func _select_units_in_rectangle(world_start: Vector2, world_end: Vector2) -> int:
	var area := Rect2(world_start, world_end - world_start).abs()
	clear_selection()
	for id in units:
		var unit: TribeUnit = units[id]
		if is_instance_valid(unit) and area.has_point(unit.global_position):
			unit.set_selected(true)
			selected_ids.append(int(id))
	return selected_ids.size()

func _screen_to_world(screen_pos: Vector2) -> Vector2:
	return get_global_transform_with_canvas().affine_inverse() * screen_pos

func _finish_pointer_gesture(screen_pos: Vector2) -> void:
	if _drag_selecting:
		_selection_end_world = _screen_to_world(screen_pos)
		_select_units_in_rectangle(_selection_start_world, _selection_end_world)
		_drag_selecting = false
		_pointer_down = false
		queue_redraw()
	elif _pointer_down:
		_pointer_down = false
		_handle_world_tap(_screen_to_world(screen_pos))

func _handle_world_tap(world_pos: Vector2) -> void:
	if scout_mode:
		ScoutSystem.dispatch_scouts(selected_ids, world_pos, units)
		scout_mode = false
		return
	if patrol_mode:
		_patrol_points.append(world_pos)
		if _patrol_points.size() >= 2:
			order_selected_patrol(_patrol_points)
			patrol_mode = false
		queue_redraw()
		return
	if rally_mode:
		set_rally_point(world_pos)
		rally_mode = false
		return
	var clicked: TribeUnit
	var best := 25.0
	for id in units:
		var unit: TribeUnit = units[id]
		if not is_instance_valid(unit):
			continue
		var distance := unit.global_position.distance_to(world_pos)
		if distance < best:
			clicked = unit
			best = distance
	if clicked != null:
		clear_selection()
		clicked.set_selected(true)
		selected_ids.append(clicked.resident_id)
	elif move_mode and not selected_ids.is_empty():
		order_selected_move(world_pos)

func _unhandled_input(event: InputEvent) -> void:
	var camera := get_parent().get_node_or_null("Camera2D")
	if event is InputEventScreenTouch and camera != null and bool(camera.get("drag_enabled")):
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_pointer_down = true
			_drag_selecting = false
			_press_screen = event.position
			_selection_start_world = _screen_to_world(event.position)
			_selection_end_world = _selection_start_world
		else:
			_finish_pointer_gesture(event.position)
	elif event is InputEventMouseMotion and _pointer_down:
		if not _drag_selecting and event.position.distance_to(_press_screen) >= 9.0:
			_drag_selecting = true
		if _drag_selecting:
			_selection_end_world = _screen_to_world(event.position)
			queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and move_mode:
			order_selected_move(get_global_mouse_position())
	elif event is InputEventScreenTouch:
		if selection_area_mode:
			if event.pressed:
				_pointer_down = true
				_drag_selecting = false
				_press_screen = event.position
				_selection_start_world = _screen_to_world(event.position)
				_selection_end_world = _selection_start_world
			else:
				_finish_pointer_gesture(event.position)
		elif event.pressed:
			_handle_world_tap(_screen_to_world(event.position))
	elif event is InputEventScreenDrag and selection_area_mode and _pointer_down:
		if not _drag_selecting and event.position.distance_to(_press_screen) >= 12.0:
			_drag_selecting = true
		if _drag_selecting:
			_selection_end_world = _screen_to_world(event.position)
			queue_redraw()
