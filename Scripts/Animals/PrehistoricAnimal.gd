extends EnemyAI
class_name PrehistoricAnimal

@export_enum("wolf", "saber_tooth", "cave_bear", "mammoth") var species: String = "wolf"
@export var passive_until_attacked: bool = false
@export var flee_health_ratio: float = 0.0

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

func _update_target() -> void:
	if passive_until_attacked and not is_instance_valid(target):
		return
	super._update_target()

func take_damage(amount: float) -> void:
	super.take_damage(amount)
	if health > 0.0 and passive_until_attacked:
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if is_instance_valid(player):
			target = player

func _draw() -> void:
	var body_color := Color("#8a7254")
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
