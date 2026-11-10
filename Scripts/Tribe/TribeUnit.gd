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

func setup(data: Dictionary) -> void:
	resident_id = int(data.get("id", -1))
	resident_name = str(data.get("name", "Dân làng"))
	resident_age = int(data.get("age", 18))
	role = str(data.get("job", data.get("role", "villager")))
	queue_redraw()

func issue_move_order(destination: Vector2) -> void:
	move_target = destination
	has_move_order = true

func set_selected(value: bool) -> void:
	selected = value
	queue_redraw()

func _process(delta: float) -> void:
	attack_timer = maxf(0.0, attack_timer - delta)
	gather_timer = maxf(0.0, gather_timer - delta)
	hunt_timer = maxf(0.0, hunt_timer - delta)
	if has_move_order:
		var offset := move_target - global_position
		if offset.length() <= 7.0:
			has_move_order = false
			global_position = move_target
		else:
			global_position += offset.normalized() * move_speed * delta
	if role == "gatherer" and resident_age >= 18 and not has_move_order and gather_timer <= 0.0:
		_auto_gather()
	if role == "hunter" and resident_age >= 18 and not has_move_order and hunt_timer <= 0.0:
		_auto_hunt()
	if combat_order_active and resident_age >= 18 and attack_timer <= 0.0:
		var target: Node2D
		var best_distance := 90.0
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or not enemy is Node2D:
				continue
			var distance := global_position.distance_to(enemy.global_position)
			if distance < best_distance:
				target = enemy
				best_distance = distance
		if target != null and target.has_method("take_damage"):
			target.take_damage(8.0)
			attack_timer = 1.4

func _draw() -> void:
	var tint := Color("#d7b16a")
	if role == "warrior":
		tint = Color("#b84b3f")
	elif role == "hunter":
		tint = Color("#668fbd")
	elif role == "gatherer":
		tint = Color("#6caa62")
	elif role == "farmer":
		tint = Color("#b4a64d")
	draw_circle(Vector2.ZERO, 10.0, tint)
	draw_arc(Vector2.ZERO, 13.0 if selected else 11.0, 0.0, TAU, 24, Color("#fff2a6") if selected else Color("#342b20"), 2.5 if selected else 1.2)
	draw_string(ThemeDB.fallback_font, Vector2(-24.0, -17.0), resident_name, HORIZONTAL_ALIGNMENT_CENTER, 48.0, 10, Color.WHITE)

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
