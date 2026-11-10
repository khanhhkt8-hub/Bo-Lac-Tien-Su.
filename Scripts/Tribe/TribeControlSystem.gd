extends Node2D
## RTS-style control for all tribe residents.

const UNIT_SCRIPT = preload("res://Scripts/Tribe/TribeUnit.gd")
var units: Dictionary = {}
var selected_ids: Array[int] = []
var move_mode := false
var _sync_timer := 0.0
var _spawn_center := Vector2.ZERO

func _ready() -> void:
	var player := get_parent().get_node_or_null("Player")
	if player != null:
		_spawn_center = player.global_position
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
	for id in units.keys():
		var resident := TribePopulation.get_resident(int(id))
		if resident.is_empty():
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

func clear_selection() -> void:
	for id in selected_ids:
		if units.has(id) and is_instance_valid(units[id]):
			(units[id] as TribeUnit).set_selected(false)
	selected_ids.clear()

func set_move_mode(enabled: bool) -> void:
	move_mode = enabled

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

func order_all_attack() -> int:
	if selected_ids.is_empty():
		select_all()
	var count := 0
	for id in selected_ids:
		if not units.has(id) or not is_instance_valid(units[id]):
			continue
		var unit: TribeUnit = units[id]
		unit.role = "warrior"
		unit.queue_redraw()
		count += 1
	return count

func get_selected_count() -> int:
	return selected_ids.size()

func _handle_world_tap(world_pos: Vector2) -> void:
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
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_world_tap(get_global_mouse_position())
		elif event.button_index == MOUSE_BUTTON_RIGHT and move_mode:
			order_selected_move(get_global_mouse_position())
	elif event is InputEventScreenTouch and event.pressed:
		var world_pos: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		_handle_world_tap(world_pos)
