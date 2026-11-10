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
	if has_move_order:
		var offset := move_target - global_position
		if offset.length() <= 7.0:
			has_move_order = false
			global_position = move_target
		else:
			global_position += offset.normalized() * move_speed * delta
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
