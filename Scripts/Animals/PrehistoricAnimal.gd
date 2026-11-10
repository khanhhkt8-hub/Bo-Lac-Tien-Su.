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
var legendary_skill_timer := 0.0
var companion_target_timer := 0.0
var companion_target: Node2D
var companion_order := "protect"
var companion_armor_equipped := false
var companion_fang_equipped := false
var rarity := "common"
var is_pack_leader := false

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

func set_rarity(rarity_id: String) -> void:
	rarity = rarity_id if rarity_id in ["common", "rare", "legendary"] else "common"
	_apply_rarity_stats()
	queue_redraw()


func _apply_rarity_stats() -> void:
	var health_multiplier := 1.0
	var damage_multiplier := 1.0
	var speed_multiplier := 1.0
	match rarity:
		"rare":
			health_multiplier = 1.25
			damage_multiplier = 1.2
			speed_multiplier = 1.08
		"legendary":
			health_multiplier = 1.7
			damage_multiplier = 1.55
			speed_multiplier = 1.18
	max_health *= health_multiplier
	attack_damage *= damage_multiplier
	move_speed *= speed_multiplier
	health = minf(health, max_health)


func _set_adult_base_stats() -> void:
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
	_apply_rarity_stats()


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
	_set_adult_base_stats()
	for _upgrade_index in range(companion_level - 1):
		max_health *= 1.2
		attack_damage *= 1.15
		move_speed *= 1.08
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
	if not is_tamed or companion_level >= 4:
		return false
	companion_level += 1
	var health_gain := 1.2
	var damage_gain := 1.15
	var speed_gain := 1.08
	if companion_level == 4:
		health_gain = 1.45
		damage_gain = 1.3
		speed_gain = 1.1
	max_health *= health_gain
	health = minf(max_health, health + max_health * (health_gain - 1.0))
	attack_damage *= damage_gain
	move_speed *= speed_gain
	queue_redraw()
	return true

func get_evolution_name() -> String:
	if companion_level >= 4:
		return "Thần Thú Giáng Thế"
	if companion_level >= 3:
		return "Cổ Thú Thức Tỉnh"
	if companion_level == 2:
		return "Thú Chiến Tinh Nhuệ"
	return "Thú Đồng Hành"


func get_companion_skill_name() -> String:
	if rarity == "legendary":
		match species:
			"wolf":
				return "Bão truy kích"
			"saber_tooth":
				return "Song trảo chí mạng"
			"cave_bear":
				return "Chấn địa cuồng nộ"
			"mammoth":
				return "Địa chấn cổ đại"
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


func _has_pack_leader_aura() -> bool:
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or node == self or not node is PrehistoricAnimal:
			continue
		var leader := node as PrehistoricAnimal
		if leader.is_pack_leader and global_position.distance_to(leader.global_position) <= 420.0:
			return true
	return false


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
	if companion_level >= 4:
		evolution_bonus *= 1.35
	var gear_bonus := 1.15 if companion_fang_equipped else 1.0
	var pack_bonus := 1.15 if _has_pack_leader_aura() else 1.0
	return base_multiplier * evolution_bonus * gear_bonus * pack_bonus


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


func _trigger_legendary_skill(primary_target: Node2D) -> void:
	if rarity != "legendary" or not is_instance_valid(primary_target):
		return
	var skill_damage := attack_damage * (1.15 if companion_level >= 4 else 0.75)
	match species:
		"saber_tooth":
			if primary_target.has_method("take_damage"):
				primary_target.take_damage(skill_damage * 1.4)
		"wolf":
			var secondary: Node2D
			var nearest_distance := 125.0
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy) or enemy == primary_target or not enemy is Node2D:
					continue
				var candidate := enemy as Node2D
				var distance := primary_target.global_position.distance_to(candidate.global_position)
				if distance < nearest_distance:
					nearest_distance = distance
					secondary = candidate
			if is_instance_valid(secondary) and secondary.has_method("take_damage"):
				secondary.take_damage(skill_damage)
		"cave_bear", "mammoth":
			var radius := 105.0 if species == "cave_bear" else 145.0
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(enemy) or enemy == self or not enemy is Node2D:
					continue
				var candidate := enemy as Node2D
				if global_position.distance_to(candidate.global_position) <= radius and candidate.has_method("take_damage"):
					candidate.take_damage(skill_damage)


func _companion_follow_and_fight(delta: float) -> void:
	legendary_skill_timer = maxf(0.0, legendary_skill_timer - delta)
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
				if legendary_skill_timer <= 0.0 and rarity == "legendary":
					legendary_skill_timer = 3.5 if companion_level >= 4 else 5.0
					_trigger_legendary_skill(companion_target)
		else:
			velocity = global_position.direction_to(companion_target.global_position) * move_speed * 1.2 * (1.1 if _has_pack_leader_aura() else 1.0)
	else:
		if not is_instance_valid(player):
			velocity = Vector2.ZERO
		else:
			var player_distance := global_position.distance_to(player.global_position)
			if player_distance > 72.0:
				velocity = global_position.direction_to(player.global_position) * move_speed * 1.25 * (1.1 if _has_pack_leader_aura() else 1.0)
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
	if rarity == "rare":
		body_color = body_color.lerp(Color("#48c8d8"), 0.5)
	elif rarity == "legendary":
		body_color = body_color.lerp(Color("#f0bd45"), 0.62)
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_circle(Vector2(-radius * 0.25, -radius * 0.15), 2.5, Color("#211b17"))
	draw_circle(Vector2(radius * 0.25, -radius * 0.15), 2.5, Color("#211b17"))
	if species == "saber_tooth":
		draw_line(Vector2(-5.0, 6.0), Vector2(-3.0, 14.0), Color("#eee1c5"), 2.0)
		draw_line(Vector2(5.0, 6.0), Vector2(3.0, 14.0), Color("#eee1c5"), 2.0)
	if is_tamed:
		var mark := "THÚ CON" if is_baby else "★%d" % companion_level
		draw_string(ThemeDB.fallback_font, Vector2(-radius, -radius - 7.0), mark, HORIZONTAL_ALIGNMENT_LEFT, 70.0, 12, Color("#f2d16b"))
	if is_tamed and companion_level >= 4:
		draw_arc(Vector2.ZERO, radius + 10.0, 0.0, TAU, 40, Color("#fff0a0"), 4.0)
	if is_tamed and is_pack_leader:
		draw_arc(Vector2.ZERO, radius + 16.0, 0.0, TAU, 48, Color("#ff7de2"), 3.5)
		draw_string(ThemeDB.fallback_font, Vector2(-radius, radius + 18.0), "THÚ CHÚA", HORIZONTAL_ALIGNMENT_LEFT, 90.0, 11, Color("#ffb6ee"))
	if is_tamed and rarity != "common":
		draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 32, body_color.lightened(0.25), 2.5)
	if species == "mammoth":
		draw_arc(Vector2(0.0, 8.0), radius * 0.65, 0.1, PI - 0.1, 18, Color("#e4d1aa"), 3.0)
