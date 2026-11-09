extends EnemyAI
class_name PrehistoricAnimal

@export_enum("wolf", "saber_tooth", "cave_bear", "mammoth") var species: String = "wolf"
@export var passive_until_attacked: bool = false
@export var flee_health_ratio: float = 0.0
var is_tamed := false
var companion_attack_timer := 0.0
var companion_target_timer := 0.0
var companion_target: Node2D

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

func _physics_process(delta: float) -> void:
	if not is_tamed:
		super._physics_process(delta)
		return
	_companion_follow_and_fight(delta)

func tame_as_companion() -> void:
	is_tamed = true
	passive_until_attacked = true
	target = null
	companion_target = null
	remove_from_group("enemies")
	add_to_group("tamed_animals")
	queue_redraw()

func _companion_follow_and_fight(delta: float) -> void:
	companion_attack_timer = maxf(0.0, companion_attack_timer - delta)
	companion_target_timer -= delta
	if companion_target_timer <= 0.0:
		companion_target_timer = 0.45
		companion_target = null
		var nearest := 230.0
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or not enemy is Node2D:
				continue
			var distance := global_position.distance_to(enemy.global_position)
			if distance < nearest:
				nearest = distance
				companion_target = enemy
	if is_instance_valid(companion_target):
		var distance := global_position.distance_to(companion_target.global_position)
		if distance <= 34.0:
			velocity = Vector2.ZERO
			if companion_attack_timer <= 0.0:
				companion_attack_timer = 1.5
				if companion_target.has_method("take_damage"):
					companion_target.take_damage(attack_damage * 0.65)
		else:
			velocity = global_position.direction_to(companion_target.global_position) * move_speed * 1.15
	else:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if not is_instance_valid(player):
			velocity = Vector2.ZERO
		else:
			var distance := global_position.distance_to(player.global_position)
			if distance > 68.0:
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
	super.take_damage(amount)
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
	if species == "mammoth":
		draw_arc(Vector2(0.0, 8.0), radius * 0.65, 0.1, PI - 0.1, 18, Color("#e4d1aa"), 3.0)
