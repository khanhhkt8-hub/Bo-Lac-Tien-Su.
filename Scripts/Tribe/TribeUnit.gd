extends Node2D
class_name TribeUnit

var resident_id: int = -1
var resident_name := "Dân làng"
var resident_age := 18
var combat_order_active := false
var role := "villager"
var move_target := Vector2.ZERO
var has_move_order := false
var selected := false
var move_speed := 105.0
var attack_timer := 0.0
var gather_timer := 0.0
var gathering_target: ResourceNode
var hunting_target: Node2D
var hunt_timer := 0.0
var defense_target: Node2D
var defense_scan_timer := 0.0
var combat_target: Node2D
var combat_scan_timer := 0.0
var hold_position_active := false
var hold_anchor := Vector2.ZERO
var hold_target: Node2D
var hold_scan_timer := 0.0
var patrol_active := false
var patrol_points: Array[Vector2] = []
var patrol_index := 0
var patrol_target: Node2D
var patrol_scan_timer := 0.0
var walk_phase := 0.0

func _ready() -> void:
	add_to_group("tribe_units")

func setup(data: Dictionary) -> void:
	resident_id = int(data.get("id", -1))
	resident_name = str(data.get("name", "Dân làng"))
	resident_age = int(data.get("age", 18))
	role = str(data.get("job", data.get("role", "villager")))
	if role == "scout":
		move_speed = 132.0
	queue_redraw()

func issue_move_order(destination: Vector2) -> void:
	combat_order_active = false
	combat_target = null
	hold_position_active = false
	hold_target = null
	patrol_active = false
	patrol_target = null
	patrol_points.clear()
	move_target = destination
	has_move_order = true

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func _process(delta: float) -> void:
	var previous_position := global_position
	attack_timer = maxf(0.0, attack_timer - delta)
	gather_timer = maxf(0.0, gather_timer - delta)
	hunt_timer = maxf(0.0, hunt_timer - delta)
	defense_scan_timer = maxf(0.0, defense_scan_timer - delta)
	combat_scan_timer = maxf(0.0, combat_scan_timer - delta)
	hold_scan_timer = maxf(0.0, hold_scan_timer - delta)
	patrol_scan_timer = maxf(0.0, patrol_scan_timer - delta)
	if has_move_order:
		var offset := move_target - global_position
		if offset.length() <= 7.0:
			has_move_order = false
			global_position = move_target
		else:
			global_position += offset.normalized() * move_speed * delta
	if patrol_active and resident_age >= 18 and not has_move_order:
		_update_patrol(delta)
	elif hold_position_active and resident_age >= 18 and not has_move_order:
		_update_hold_position(delta)
	elif combat_order_active and resident_age >= 18 and not has_move_order:
		_update_combat_order(delta)
	if role == "warrior" and resident_age >= 18 and not has_move_order and not combat_order_active and not hold_position_active and not patrol_active:
		_auto_defend(delta)
	if role == "gatherer" and resident_age >= 18 and not has_move_order and not combat_order_active and not hold_position_active and not patrol_active and gather_timer <= 0.0:
		_auto_gather()
	if role == "hunter" and resident_age >= 18 and not has_move_order and not combat_order_active and not hold_position_active and not patrol_active and hunt_timer <= 0.0:
		_auto_hunt()
	if global_position.distance_squared_to(previous_position) > 0.1:
		walk_phase += delta * 12.0
		queue_redraw()

func set_hold_position() -> void:
	patrol_active = false
	patrol_points.clear()
	patrol_target = null
	hold_anchor = global_position
	hold_position_active = resident_age >= 18
	hold_target = null
	combat_order_active = false
	combat_target = null
	has_move_order = false
	gathering_target = null
	hunting_target = null
	hold_scan_timer = 0.0

func set_patrol_route(points: Array[Vector2]) -> void:
	if resident_age < 18 or points.size() < 2:
		return
	patrol_points = points.duplicate()
	patrol_index = 0
	patrol_active = true
	patrol_target = null
	combat_order_active = false
	combat_target = null
	hold_position_active = false
	hold_target = null
	has_move_order = false
	gathering_target = null
	hunting_target = null

func _update_patrol(delta: float) -> void:
	if patrol_points.size() < 2:
		patrol_active = false
		return
	if patrol_scan_timer <= 0.0 or not is_instance_valid(patrol_target) or patrol_target.is_queued_for_deletion():
		patrol_scan_timer = 0.35
		patrol_target = null
		var nearest := 180.0
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy is Node2D:
				continue
			var candidate := enemy as Node2D
			var distance := global_position.distance_to(candidate.global_position)
			if distance < nearest and candidate.global_position.distance_to(patrol_points[patrol_index]) <= 230.0:
				nearest = distance
				patrol_target = candidate
	if is_instance_valid(patrol_target):
		var offset := patrol_target.global_position - global_position
		var distance_to_target := offset.length()
		var preferred_range := 28.0
		var damage := 8.0
		var cooldown := 1.3
		if role == "hunter":
			preferred_range = 135.0
			damage = 11.0
			cooldown = 1.8
		elif role != "warrior":
			preferred_range = 78.0
			damage = 5.0
			cooldown = 1.6
		if global_position.distance_to(patrol_points[patrol_index]) > 205.0:
			patrol_target = null
		elif distance_to_target > preferred_range + 10.0:
			global_position += offset.normalized() * move_speed * delta
		elif distance_to_target < preferred_range - 20.0 and role == "hunter":
			global_position -= offset.normalized() * move_speed * 0.6 * delta
		elif attack_timer <= 0.0 and patrol_target.has_method("take_damage"):
			patrol_target.take_damage(damage)
			attack_timer = cooldown
		if is_instance_valid(patrol_target) and not patrol_target.is_queued_for_deletion():
			return
		patrol_target = null
	var waypoint := patrol_points[patrol_index]
	var route_offset := waypoint - global_position
	if route_offset.length() <= 18.0:
		patrol_index = (patrol_index + 1) % patrol_points.size()
		waypoint = patrol_points[patrol_index]
		route_offset = waypoint - global_position
	if route_offset.length() > 6.0:
		global_position += route_offset.normalized() * move_speed * delta

func _update_hold_position(delta: float) -> void:
	if hold_scan_timer <= 0.0 or not is_instance_valid(hold_target) or hold_target.is_queued_for_deletion():
		hold_scan_timer = 0.35
		hold_target = null
		var nearest := 230.0
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy is Node2D:
				continue
			var candidate := enemy as Node2D
			if candidate.global_position.distance_to(hold_anchor) > 245.0:
				continue
			var distance := global_position.distance_to(candidate.global_position)
			if distance < nearest:
				nearest = distance
				hold_target = candidate
	if not is_instance_valid(hold_target):
		var return_offset := hold_anchor - global_position
		if return_offset.length() > 16.0:
			global_position += return_offset.normalized() * move_speed * delta
		return
	var target_offset := hold_target.global_position - global_position
	var distance_to_target := target_offset.length()
	var preferred_range := 30.0
	var damage := 8.0
	var cooldown := 1.3
	if role == "hunter":
		preferred_range = 140.0
		damage = 10.0
		cooldown = 1.8
	elif role != "warrior":
		preferred_range = 82.0
		damage = 5.0
		cooldown = 1.6
	if global_position.distance_to(hold_anchor) > 205.0:
		hold_target = null
		return
	if distance_to_target > preferred_range + 10.0:
		global_position += target_offset.normalized() * move_speed * delta
	elif distance_to_target < preferred_range - 22.0 and role == "hunter":
		global_position -= target_offset.normalized() * move_speed * 0.6 * delta
	elif attack_timer <= 0.0 and hold_target.has_method("take_damage"):
		hold_target.take_damage(damage)
		attack_timer = cooldown

func _update_combat_order(delta: float) -> void:
	if combat_scan_timer <= 0.0 or not is_instance_valid(combat_target) or combat_target.is_queued_for_deletion():
		combat_scan_timer = 0.35
		combat_target = null
		var nearest := 520.0
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy is Node2D:
				continue
			var candidate := enemy as Node2D
			var distance := global_position.distance_to(candidate.global_position)
			if distance < nearest:
				nearest = distance
				combat_target = candidate
	if not is_instance_valid(combat_target):
		return
	var distance_to_target := global_position.distance_to(combat_target.global_position)
	var preferred_range := 30.0
	var damage := 8.0
	var cooldown := 1.3
	if role == "hunter":
		preferred_range = 145.0
		damage = 12.0
		cooldown = 1.8
	elif role != "warrior":
		preferred_range = 85.0
		damage = 5.0
		cooldown = 1.6
	if distance_to_target > preferred_range + 12.0:
		global_position += global_position.direction_to(combat_target.global_position) * move_speed * delta
	elif distance_to_target < preferred_range - 25.0 and role == "hunter":
		global_position += combat_target.global_position.direction_to(global_position) * move_speed * 0.65 * delta
	elif attack_timer <= 0.0 and combat_target.has_method("take_damage"):
		combat_target.take_damage(damage)
		attack_timer = cooldown
	if not is_instance_valid(combat_target) or combat_target.is_queued_for_deletion():
		combat_target = null

func _auto_defend(delta: float) -> void:
	if defense_scan_timer <= 0.0 or not is_instance_valid(defense_target):
		defense_scan_timer = 0.35
		defense_target = null
		var best_distance := 260.0
		var protected_nodes: Array[Node2D] = []
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if is_instance_valid(player):
			protected_nodes.append(player)
		for unit in get_tree().get_nodes_in_group("tribe_units"):
			if not is_instance_valid(unit) or unit == self or not unit is Node2D:
				continue
			protected_nodes.append(unit as Node2D)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or not enemy is Node2D:
				continue
			var enemy_node := enemy as Node2D
			var threatens_tribe := false
			for protected in protected_nodes:
				if is_instance_valid(protected) and enemy_node.global_position.distance_to(protected.global_position) <= 210.0:
					threatens_tribe = true
					break
			if not threatens_tribe:
				continue
			var distance := global_position.distance_to(enemy_node.global_position)
			if distance < best_distance:
				best_distance = distance
				defense_target = enemy_node
	if not is_instance_valid(defense_target):
		return
	var distance_to_target := global_position.distance_to(defense_target.global_position)
	if distance_to_target > 34.0:
		global_position += global_position.direction_to(defense_target.global_position) * move_speed * delta
	else:
		if attack_timer <= 0.0 and defense_target.has_method("take_damage"):
			defense_target.take_damage(9.0)
			attack_timer = 1.1
		if not is_instance_valid(defense_target) or defense_target.is_queued_for_deletion():
			defense_target = null

func _draw() -> void:
	var tint := Color("#d7b16a")
	var role_mark := "D"
	if role == "warrior":
		tint = Color("#b84b3f")
		role_mark = "⚔"
	elif role == "hunter":
		tint = Color("#668fbd")
		role_mark = "➤"
	elif role == "gatherer":
		tint = Color("#6caa62")
		role_mark = "✦"
	elif role == "farmer":
		tint = Color("#b4a64d")
		role_mark = "✿"
	elif role == "scout":
		tint = Color("#55a99b")
		role_mark = "!"
	elif role == "crafter":
		tint = Color("#a18ac0")
		role_mark = "◆"
	# Bóng, thân người, đầu tóc và trang phục theo nghề.
	draw_colored_polygon(PackedVector2Array([Vector2(-9, 7), Vector2(-6, 15), Vector2(7, 15), Vector2(10, 7)]), Color(0.10, 0.13, 0.09, 0.35))
	var step := sin(walk_phase) * 3.5 if has_move_order or patrol_active or combat_order_active else 0.0
	draw_line(Vector2(-4, 5), Vector2(-5.0 - step, 12), Color("#49352a"), 4.0)
	draw_line(Vector2(4, 5), Vector2(5.0 + step, 12), Color("#49352a"), 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -5), Vector2(-7, 7), Vector2(0, 10), Vector2(7, 7), Vector2(8, -5), Vector2(0, -9)]), tint)
	draw_line(Vector2(-7, -2), Vector2(7, 6), Color("#e0c89b"), 2.0)
	draw_circle(Vector2(0, -10), 7.0, Color("#d9a066"))
	draw_arc(Vector2(0, -12), 7.0, PI, TAU, 16, Color("#3a2a20"), 3.5)
	draw_circle(Vector2(-2.5, -10), 1.0, Color("#292018"))
	draw_circle(Vector2(2.5, -10), 1.0, Color("#292018"))
	draw_arc(Vector2.ZERO, 15.0 if selected else 12.0, 0.0, TAU, 28, Color("#fff2a6") if selected else Color("#342b20"), 2.5 if selected else 1.0)
	draw_circle(Vector2(10, -11), 5.0, Color("#27372d"))
	draw_string(ThemeDB.fallback_font, Vector2(6, -8), role_mark, HORIZONTAL_ALIGNMENT_CENTER, 9.0, 9, Color("#fff1c8"))
	draw_string(ThemeDB.fallback_font, Vector2(-34.0, -24.0), resident_name, HORIZONTAL_ALIGNMENT_CENTER, 68.0, 10, Color.WHITE)

func _auto_gather() -> void:
	if not is_instance_valid(gathering_target) or gathering_target.amount_available <= 0:
		gathering_target = null
		var nearest_distance := 260.0
		for candidate in get_tree().get_nodes_in_group("resource_nodes"):
			if not is_instance_valid(candidate) or not candidate is ResourceNode:
				continue
			var distance := global_position.distance_to(candidate.global_position)
			if distance < nearest_distance and candidate.amount_available > 0:
				nearest_distance = distance
				gathering_target = candidate
		if is_instance_valid(gathering_target):
			issue_move_order(gathering_target.global_position)
			return
		gather_timer = 1.5
	if is_instance_valid(gathering_target):
		if global_position.distance_to(gathering_target.global_position) <= 28.0:
			if gathering_target.gather_for_tribe():
				gather_timer = 2.5
			gathering_target = null
			has_move_order = false

func _auto_hunt() -> void:
	if not is_instance_valid(hunting_target) or hunting_target.is_queued_for_deletion():
		hunting_target = null
		var nearest_distance := 340.0
		for candidate in get_tree().get_nodes_in_group("prehistoric_animals"):
			if not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
				continue
			if candidate.get("is_tamed") == true or candidate.get("is_baby") == true or candidate.has_meta("hunter_reserved"):
				continue
			var distance := global_position.distance_to(candidate.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				hunting_target = candidate
		if is_instance_valid(hunting_target):
			hunting_target.set_meta("hunter_reserved", resident_id)
			if hunting_target.has_signal("defeated"):
				var callback := Callable(self, "_on_hunted_animal_defeated")
				if not hunting_target.defeated.is_connected(callback):
					hunting_target.defeated.connect(callback, CONNECT_ONE_SHOT)
			issue_move_order(hunting_target.global_position)
			return
		hunt_timer = 2.0
	if is_instance_valid(hunting_target):
		var distance := global_position.distance_to(hunting_target.global_position)
		if distance > 38.0:
			issue_move_order(hunting_target.global_position)
		else:
			if hunting_target.has_method("take_damage"):
				hunting_target.take_damage(7.0)
			hunt_timer = 1.0
			if not is_instance_valid(hunting_target) or hunting_target.is_queued_for_deletion():
				hunting_target = null

func _on_hunted_animal_defeated(animal: Node) -> void:
	if TribeJobSystem == null:
		return
	var meat_reward := 4
	match str(animal.get("species")):
		"saber_tooth":
			meat_reward = 7
		"cave_bear":
			meat_reward = 10
		"mammoth":
			meat_reward = 14
	TribeJobSystem.add_to_stockpile("meat", meat_reward)
	hunting_target = null
	hunt_timer = 2.0
