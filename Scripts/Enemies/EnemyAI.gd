extends CharacterBody2D
class_name EnemyAI

signal defeated(enemy: EnemyAI)

enum AIState { PATROL, CHASE, ATTACK, RETURN }

@export var enemy_name: String = "Enemy"
@export var max_health: float = 60.0
@export var move_speed: float = 82.0
@export var detection_range: float = 210.0
@export var attack_range: float = 30.0
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.4
@export var patrol_radius: float = 110.0

var health: float
var surrendered := false
var state: AIState = AIState.PATROL
var home_position: Vector2
var patrol_target: Vector2
var target: Node2D
var attack_timer: float = 0.0
var retarget_timer: float = 0.0
var slow_seconds: float = 0.0
var slow_multiplier: float = 1.0
var poison_seconds: float = 0.0
var poison_damage: float = 0.0
var poison_tick_timer: float = 0.0
var hit_flash := 0.0

func _ready() -> void:
	health = max_health
	home_position = global_position
	_choose_patrol_point()
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	if surrendered:
		var escape_direction := global_position.direction_to(home_position)
		velocity = escape_direction * move_speed * 0.7
		move_and_slide()
		queue_redraw()
		return
	attack_timer = maxf(0.0, attack_timer - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	slow_seconds = maxf(0.0, slow_seconds - delta)
	if slow_seconds <= 0.0:
		slow_multiplier = 1.0
	poison_seconds = maxf(0.0, poison_seconds - delta)
	if poison_seconds > 0.0:
		poison_tick_timer -= delta
		if poison_tick_timer <= 0.0:
			poison_tick_timer = 1.0
			take_damage(poison_damage)
	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = 0.25
		_update_target()
	_update_state()
	_move_ai(delta)
	move_and_slide()
	queue_redraw()

func _update_target() -> void:
	if is_instance_valid(target) and not target.is_queued_for_deletion():
		if global_position.distance_to(target.global_position) <= detection_range * 1.45:
			return
	target = null
	var nearest := detection_range
	var candidates: Array[Node2D] = []
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(player):
		candidates.append(player)
	for unit in get_tree().get_nodes_in_group("tribe_units"):
		if not is_instance_valid(unit) or unit.is_queued_for_deletion() or not unit is Node2D:
			continue
		candidates.append(unit as Node2D)
	for candidate in candidates:
		var distance := global_position.distance_to(candidate.global_position)
		if distance <= nearest:
			nearest = distance
			target = candidate
	if is_instance_valid(target):
		_on_target_detected(target)

func _update_state() -> void:
	if is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance <= attack_range:
			state = AIState.ATTACK
		else:
			state = AIState.CHASE
	elif global_position.distance_to(home_position) > patrol_radius * 1.8:
		state = AIState.RETURN
	else:
		state = AIState.PATROL

func _move_ai(_delta: float) -> void:
	var destination := global_position
	match state:
		AIState.CHASE:
			if is_instance_valid(target):
				destination = target.global_position
		AIState.ATTACK:
			velocity = Vector2.ZERO
			_try_attack()
			return
		AIState.RETURN:
			destination = home_position
		AIState.PATROL:
			destination = patrol_target
			if global_position.distance_to(patrol_target) < 12.0:
				_choose_patrol_point()
	var direction := global_position.direction_to(destination)
	velocity = direction * move_speed * slow_multiplier
	if direction.length_squared() > 0.01:
		rotation = direction.angle()

func _try_attack() -> void:
	if attack_timer > 0.0 or not is_instance_valid(target):
		return
	attack_timer = attack_cooldown
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)

func _choose_patrol_point() -> void:
	var angle := randf() * TAU
	var distance := randf_range(patrol_radius * 0.25, patrol_radius)
	patrol_target = home_position + Vector2.RIGHT.rotated(angle) * distance

func _on_target_detected(_new_target: Node2D) -> void:
	pass


func apply_slow(duration: float, multiplier: float) -> void:
	slow_seconds = maxf(slow_seconds, duration)
	slow_multiplier = minf(slow_multiplier, clampf(multiplier, 0.1, 1.0))

func apply_poison(duration: float, damage_per_second: float) -> void:
	poison_seconds = maxf(poison_seconds, duration)
	poison_damage = maxf(poison_damage, damage_per_second)
	poison_tick_timer = minf(poison_tick_timer, 1.0) if poison_tick_timer > 0.0 else 1.0

	queue_redraw()

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - maxf(0.0, amount))
	hit_flash = 0.16
	if not surrendered and health > 0.0 and health <= max_health * 0.25 and not bool(get("is_chief")):
		surrendered = true
		target = null
		add_to_group("surrendered_barbarians")
	queue_redraw()
	if health <= 0.0 and not is_queued_for_deletion():
		defeated.emit(self)
		queue_free()

func _draw() -> void:
	# Bóng, giáp da ghép mảng và phụ kiện chiến binh.
	draw_colored_polygon(PackedVector2Array([Vector2(-14, 8), Vector2(-11, 18), Vector2(11, 18), Vector2(14, 8)]), Color(0.07, 0.07, 0.06, 0.42))
	draw_line(Vector2(-6, 7), Vector2(-8, 15), Color("#30231d"), 6.0)
	draw_line(Vector2(6, 7), Vector2(8, 15), Color("#30231d"), 6.0)
	var armor_color := Color("#704735").lerp(Color.WHITE, clampf(hit_flash / 0.16, 0.0, 1.0))
	draw_colored_polygon(PackedVector2Array([Vector2(-12, -8), Vector2(-9, 8), Vector2(0, 13), Vector2(9, 8), Vector2(12, -8), Vector2(0, -13)]), armor_color.darkened(0.32))
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -7), Vector2(-7, 7), Vector2(0, 10), Vector2(7, 7), Vector2(9, -7), Vector2(0, -11)]), armor_color)
	# Tấm giáp vai, dây da và đinh tán.
	draw_colored_polygon(PackedVector2Array([Vector2(-10, -6), Vector2(-15, -3), Vector2(-12, 3), Vector2(-7, 1)]), Color("#8b6545"))
	draw_colored_polygon(PackedVector2Array([Vector2(10, -6), Vector2(15, -3), Vector2(12, 3), Vector2(7, 1)]), Color("#8b6545"))
	draw_line(Vector2(-8, -4), Vector2(8, 6), Color("#d0a46a"), 2.5)
	draw_line(Vector2(-7, 5), Vector2(7, 5), Color("#4a3024"), 1.5)
	draw_circle(Vector2(-6, -2), 1.2, Color("#e0c18b"))
	draw_circle(Vector2(6, 4), 1.2, Color("#e0c18b"))
	# Đầu, tóc dựng, sơn chiến trận và gương mặt.
	draw_circle(Vector2(0, -13), 10.5, Color("#a86f4d"))
	draw_arc(Vector2(0, -16), 10.5, PI, TAU, 18, Color("#39251e"), 4.5)
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -16), Vector2(-5, -25), Vector2(0, -20), Vector2(5, -26), Vector2(10, -15)]), Color("#39251e"))
	draw_line(Vector2(-8, -8), Vector2(8, -5), Color("#a83c32"), 2.0)
	draw_circle(Vector2(-3.5, -13), 1.5, Color("#241a16"))
	draw_circle(Vector2(3.5, -13), 1.5, Color("#241a16"))
	draw_line(Vector2(-2, -7), Vector2(2, -7), Color("#573326"), 1.3)
	# Khiên gỗ nhỏ và vũ khí đá.
	draw_colored_polygon(PackedVector2Array([Vector2(-16, -2), Vector2(-22, 2), Vector2(-20, 12), Vector2(-14, 15), Vector2(-10, 9)]), Color("#6c472e"))
	draw_arc(Vector2(-16, 6), 7.0, -1.2, 1.3, 12, Color("#c18a50"), 1.8)
	draw_line(Vector2(11, -3), Vector2(21, -19), Color("#503624"), 3.2)
	draw_colored_polygon(PackedVector2Array([Vector2(18, -22), Vector2(25, -29), Vector2(25, -17), Vector2(20, -14)]), Color("#b9c0b4"))
	draw_line(Vector2(20, -22), Vector2(24, -26), Color("#edf0df"), 1.2)
	# Thanh máu và hiệu ứng trúng đòn.
	draw_rect(Rect2(Vector2(-17.0, -33.0), Vector2(34.0, 5.0)), Color("#292521"))
	draw_rect(Rect2(Vector2(-16.0, -32.0), Vector2(32.0 * health / maxf(1.0, max_health), 3.0)), Color("#d84e43"))
	if hit_flash > 0.0:
		for spark_index in range(7):
			var angle := TAU * float(spark_index) / 7.0
			var start := Vector2(cos(angle), sin(angle)) * 16.0
			var finish := Vector2(cos(angle), sin(angle)) * 26.0
			draw_line(start, finish, Color("#ffe08a"), 2.0)
