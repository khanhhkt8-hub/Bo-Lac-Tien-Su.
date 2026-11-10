extends EnemyAI
class_name PrehistoricAnimal

@export_enum("wolf", "saber_tooth", "cave_bear", "mammoth") var species: String = "wolf"
@export var passive_until_attacked: bool = false
@export var flee_health_ratio: float = 0.0
var is_tamed := false
var is_mounted := false
var mount_owner: Node2D
var companion_level := 1
var is_baby := false
var growth_seconds_remaining := 0.0
var companion_attack_timer := 0.0
var companion_target_timer := 0.0
var companion_target: Node2D
var companion_order := "protect"
var companion_armor_equipped := false
var companion_fang_equipped := false

func _ready() -> void:
	match species:
		"wolf":
			enemy_name = "Prehistoric Wolf"
			max_health = 45.0
			move_speed = 112.0
			attack_damage = 7.0
		"saber_tooth":
			enemy_name = "Saber-toothed Tiger"
			max_health = 90.0
			move_speed = 128.0
			attack_damage = 17.0
		"cave_bear":
			enemy_name = "Cave Bear"
			max_health = 150.0
			move_speed = 76.0
			attack_damage = 22.0
		"mammoth":
			enemy_name = "Mammoth"
			max_health = 260.0
			move_speed = 58.0
			attack_damage = 28.0
	super._ready()
	add_to_group("prehistoric_animals")

func _process(delta: float) -> void:
	if is_tamed and is_baby:
		growth_seconds_remaining = maxf(0.0, growth_seconds_remaining - delta)
		if growth_seconds_remaining <= 0.0:
			_grow_into_adult()

func set_as_baby(growth_seconds: float = 300.0) -> void:
	is_baby = true
	growth_seconds_remaining = maxf(1.0, growth_seconds)
	scale = Vector2.ONE * 0.62
	max_health *= 0.55
	health = max_health
	attack_damage *= 0.35
	move_speed *= 0.8
	queue_redraw()

func _grow_into_adult() -> void:
	is_baby = false
	growth_seconds_remaining = 0.0
	scale = Vector2.ONE
	match species:
		"wolf":
			max_health = 45.0
			move_speed = 112.0
			attack_damage = 7.0
		"saber_tooth":
			max_health = 90.0
			move_speed = 128.0
			attack_damage = 17.0
		"cave_bear":
			max_health = 150.0
			move_speed = 76.0
			attack_damage = 22.0
		"mammoth":
			max_health = 260.0
			move_speed = 58.0
			attack_damage = 28.0
	health = max_health
	queue_redraw()

func _physics_process(delta: float) -> void:
	if is_mounted:
		if is_instance_valid(mount_owner):
			global_position = mount_owner.global_position + Vector2(0.0, 18.0)
		velocity = Vector2.ZERO
		return
	if not is_tamed:
		super._physics_process(delta)
		return
	_companion_follow_and_fight(delta)

func tame_as_companion() -> void:
	is_tamed = true
	passive_until_attacked = true
	target = null
	companion_target = null
	companion_order = "protect"
	remove_from_group("enemies")
	remove_from_group("cave_wildlife")
	add_to_group("tamed_animals")
	queue_redraw()

func get_mount_speed_multiplier() -> float:
	match species:
		"wolf":
			return 1.6
		"saber_tooth":
			return 1.8
		"cave_bear":
			return 1.15
		"mammoth":
			return 1.35
	return 1.0

func upgrade_companion() -> bool:
	if not is_tamed or companion_level >= 3:
		return false
	companion_level += 1
	max_health *= 1.2
	health = minf(max_health, health + max_health * 0.2)
	attack_damage *= 1.15
	move_speed *= 1.08
	queue_redraw()
	return true

func get_evolution_name() -> String:
	if companion_level >= 3:
		return "Cổ Thú Thức Tỉnh"
	if companion_level == 2:
		return "Thú Chiến Tinh Nhuệ"
	return "Thú Đồng Hành"


func get_companion_skill_name() -> String:
	match species:
		"wolf":
			return "Truy kích nhanh"
		"saber_tooth":
			return "Vồ xé"
		"cave_bear":
			return "Gấu cuồng nộ"
		"mammoth":
			return "Dậm nghiền"
	return "Đòn đánh thường"


func set_companion_order(order: String) -> void:
	if order not in ["protect", "attack"]:
		return
	companion_order = order
	companion_target = null
	companion_target_timer = 0.0


func _get_skill_damage_multiplier() -> float:
	var base_multiplier := 1.0
	match species:
		"wolf":
			base_multiplier = 0.9
		"saber_tooth":
			base_multiplier = 1.65
		"cave_bear":
			base_multiplier = 1.85
		"mammoth":
			base_multiplier = 2.1
	var evolution_bonus := 1.0 + float(companion_level - 1) * 0.25
	var gear_bonus := 1.15 if companion_fang_equipped else 1.0
	return base_multiplier * evolution_bonus * gear_bonus


func _get_skill_cooldown() -> float:
	match species:
		"wolf":
			return 0.85
		"saber_tooth":
			return 1.35
		"cave_bear":
			return 1.7
		"mammoth":
			return 2.0
	return 1.5


func _companion_follow_and_fight(delta: float) -> void:
	companion_attack_timer = maxf(0.0, companion_attack_timer - delta)
	companion_target_timer -= delta
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if companion_target_timer <= 0.0:
		companion_target_timer = 0.4
		companion_target = null
		if not is_baby:
			var nearest := 520.0 if companion_order == "attack" else 210.0
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy) or not enemy is Node2D:
					continue
				var enemy_node := enemy as Node2D
				var distance := global_position.distance_to(enemy_node.global_position)
				if companion_order == "protect" and is_instance_valid(player):
					if player.global_position.distance_to(enemy_node.global_position) > 210.0:
						continue
				if distance < nearest:
					nearest = distance
					companion_target = enemy_node
	if is_instance_valid(companion_target):
		var target_distance := global_position.distance_to(companion_target.global_position)
		if target_distance <= 36.0:
			velocity = Vector2.ZERO
			if companion_attack_timer <= 0.0 and companion_target.has_method("take_damage"):
				companion_attack_timer = _get_skill_cooldown()
				companion_target.take_damage(attack_damage * _get_skill_damage_multiplier())
		else:
			velocity = global_position.direction_to(companion_target.global_position) * move_speed * 1.2
	else:
		if not is_instance_valid(player):
			velocity = Vector2.ZERO
		else:
			var player_distance := global_position.distance_to(player.global_position)
			if player_distance > 72.0:
				velocity = global_position.direction_to(player.global_position) * move_speed * 1.25
			else:
				velocity = Vector2.ZERO
	if velocity.length_squared() > 1.0:
		rotation = velocity.angle()
	move_and_slide()
	queue_redraw()

func _update_target() -> void:
	if is_tamed:
		return
	if passive_until_attacked and not is_instance_valid(target):
		return
	super._update_target()

func take_damage(amount: float) -> void:
	var adjusted_damage := amount * (0.7 if is_tamed and companion_armor_equipped else 1.0)
	super.take_damage(adjusted_damage)
	if health > 0.0 and passive_until_attacked and not is_tamed:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if is_instance_valid(player):
			target = player

func _draw() -> void:
	var body_color := Color("#8a7254")
	if is_tamed:
		body_color = Color("#78b88a")
	var radius := 16.0
	match species:
		"wolf":
			body_color = Color("#77736a")
			radius = 13.0
		"saber_tooth":
			body_color = Color("#c18a52")
			radius = 17.0
		"cave_bear":
			body_color = Color("#49352c")
			radius = 21.0
		"mammoth":
			body_color = Color("#8a7964")
			radius = 27.0
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.15), 2.5, Color("#211b17"))
	draw_circle(Vector2(radius * 0.25, -radius * 0.15), 2.5, Color("#211b17"))
	if species == "saber_tooth":
		draw_line(Vector2(-5.0, 6.0), Vector2(-3.0, 14.0), Color("#eee1c5"), 2.0)
		draw_line(Vector2(5.0, 6.0), Vector2(3.0, 14.0), Color("#eee1c5"), 2.0)
	if is_tamed:
		var mark := "THÚ CON" if is_baby else "★%d" % companion_level
		draw_string(ThemeDB.fallback_font, Vector2(-radius, -radius - 7.0), mark, HORIZONTAL_ALIGNMENT_LEFT, 70.0, 12, Color("#f2d16b"))
	if species == "mammoth":
		draw_arc(Vector2(0.0, 8.0), radius * 0.65, 0.1, PI - 0.1, 18, Color("#e4d1aa"), 3.0)
