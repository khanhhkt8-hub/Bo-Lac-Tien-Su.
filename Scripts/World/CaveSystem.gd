extends Node2D
## A separate underground pocket in the same offline world. Touch the marked entrance to enter.

const ANIMAL_SCENE: PackedScene = preload("res://Scenes/PrehistoricAnimal.tscn")
const CAVERN_SURFACE := Vector2(1100.0, 1000.0)
const CAVE_CENTER := Vector2(10000.0, 10000.0)
const ROOM_SIZE := Vector2(560.0, 420.0)

var inside_cave := false
var _entry_gate: Area2D
var _exit_gate: Area2D

func _ready() -> void:
	_create_entry_gate()
	_create_exit_gate()
	queue_redraw()

func _create_entry_gate() -> void:
	_entry_gate = _make_gate("CaveEntrance", CAVERN_SURFACE + Vector2(0.0, 470.0))
	_entry_gate.body_entered.connect(_on_entry_touched)

func _create_exit_gate() -> void:
	_exit_gate = _make_gate("CaveExit", CAVE_CENTER + Vector2(0.0, 145.0))
	_exit_gate.body_entered.connect(_on_exit_touched)

func _make_gate(gate_name: String, gate_position: Vector2) -> Area2D:
	var gate := Area2D.new()
	gate.name = gate_name
	gate.position = gate_position
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 42.0
	shape_node.shape = circle
	gate.add_child(shape_node)
	add_child(gate)
	return gate

func _on_entry_touched(body: Node2D) -> void:
	if inside_cave or not body.is_in_group("player"):
		return
	inside_cave = true
	body.global_position = CAVE_CENTER + Vector2(0.0, 70.0)
	_spawn_cave_wildlife()
	print("Đã vào Hang Động Cổ Xưa. Hãy khám phá và tìm lối ra.")

func _on_exit_touched(body: Node2D) -> void:
	if not inside_cave or not body.is_in_group("player"):
		return
	inside_cave = false
	body.global_position = CAVERN_SURFACE + Vector2(0.0, 410.0)
	_clear_cave_wildlife()
	print("Đã rời Hang Động Cổ Xưa.")

func _spawn_cave_wildlife() -> void:
	_clear_cave_wildlife()
	var bear := ANIMAL_SCENE.instantiate() as PrehistoricAnimal
	bear.species = "cave_bear"
	add_child(bear)
	bear.global_position = CAVE_CENTER + Vector2(-125.0, -65.0)
	bear.add_to_group("cave_wildlife")
	var tiger := ANIMAL_SCENE.instantiate() as PrehistoricAnimal
	tiger.species = "saber_tooth"
	add_child(tiger)
	tiger.global_position = CAVE_CENTER + Vector2(145.0, -105.0)
	tiger.add_to_group("cave_wildlife")

func _clear_cave_wildlife() -> void:
	for animal in get_tree().get_nodes_in_group("cave_wildlife"):
		if is_instance_valid(animal) and not animal.is_in_group("tamed_animals"):
			animal.queue_free()

func _process(_delta: float) -> void:
	if not inside_cave:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var half := ROOM_SIZE * 0.5 - Vector2(28.0, 28.0)
	var relative := player.global_position - CAVE_CENTER
	player.global_position = CAVE_CENTER + Vector2(
		clampf(relative.x, -half.x, half.x),
		clampf(relative.y, -half.y, half.y)
	)

func _draw() -> void:
	# Entrance marker on the cavern surface.
	draw_circle(CAVERN_SURFACE + Vector2(0.0, 470.0), 36.0, Color(0.08, 0.07, 0.06, 0.75))
	draw_arc(CAVERN_SURFACE + Vector2(0.0, 470.0), 42.0, 0.0, TAU, 32, Color("#d1b47a"), 4.0)
	draw_string(ThemeDB.fallback_font, CAVERN_SURFACE + Vector2(-80.0, 420.0), "LỐI VÀO HANG", HORIZONTAL_ALIGNMENT_LEFT, 180.0, 17, Color("#fff0c7"))
	# Underground chamber is drawn far outside the surface map.
	draw_rect(Rect2(CAVE_CENTER - ROOM_SIZE * 0.5, ROOM_SIZE), Color("#252522"))
	draw_rect(Rect2(CAVE_CENTER - ROOM_SIZE * 0.5, ROOM_SIZE), Color("#77664d"), false, 14.0)
	for i in range(9):
		var x := CAVE_CENTER.x - 220.0 + float(i) * 55.0
		draw_circle(Vector2(x, CAVE_CENTER.y - 155.0 + sin(float(i) * 1.7) * 18.0), 12.0 + float(i % 3) * 5.0, Color("#51483d"))
		draw_circle(Vector2(x + 16.0, CAVE_CENTER.y + 165.0), 10.0 + float(i % 2) * 6.0, Color("#494239"))
	draw_string(ThemeDB.fallback_font, CAVE_CENTER + Vector2(-105.0, -165.0), "HANG ĐỘNG CỔ XƯA", HORIZONTAL_ALIGNMENT_LEFT, 260.0, 22, Color("#e8d8b5"))
	draw_string(ThemeDB.fallback_font, CAVE_CENTER + Vector2(-78.0, 205.0), "LỐI RA", HORIZONTAL_ALIGNMENT_LEFT, 160.0, 18, Color("#fff0c7"))
