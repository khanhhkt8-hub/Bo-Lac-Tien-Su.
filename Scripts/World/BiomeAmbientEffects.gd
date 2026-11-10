extends Node2D
class_name BiomeAmbientEffects

@export var particle_count: int = 42
var _elapsed := 0.0
var _player: Node2D
var _region_id := ""

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	z_index = 8

func _process(delta: float) -> void:
	_elapsed += delta
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(_player):
		global_position = _player.global_position
	if is_instance_valid(RegionSystem):
		_region_id = str(RegionSystem.current_region_id)
		if _region_id.is_empty() and is_instance_valid(_player):
			_region_id = RegionSystem.get_region_id_at(_player.global_position)
	queue_redraw()

func _draw() -> void:
	match _region_id:
		"primeval_forest":
			_draw_forest()
		"grassland":
			_draw_grassland()
		"swampland":
			_draw_swamp()
		"cavern":
			_draw_cavern()
		"frostlands":
			_draw_frost()
		_:
			_draw_heartland()

func _particle_position(index: int, speed: float, spread_x: float = 440.0, spread_y: float = 300.0) -> Vector2:
	var i := float(index)
	return Vector2(
		fposmod(i * 83.17 + sin(i * 2.31) * 47.0 + _elapsed * speed, spread_x * 2.0) - spread_x,
		fposmod(i * 51.73 + cos(i * 1.71) * 35.0 + _elapsed * speed * 0.37, spread_y * 2.0) - spread_y
	)

func _draw_forest() -> void:
	# Lá rừng vàng xanh xoay nhẹ và trôi theo gió.
	for i in range(particle_count):
		var p := _particle_position(i, 17.0, 430.0, 290.0)
		var sway := sin(_elapsed * 1.8 + float(i)) * 5.0
		var leaf_color := Color("#b7c96b") if i % 3 == 0 else Color("#789b4c")
		draw_line(p, p + Vector2(4.0 + sway * 0.25, 2.0), Color(leaf_color, 0.72), 2.2, true)
		draw_circle(p, 1.5, Color(0.88, 0.82, 0.48, 0.48))

func _draw_grassland() -> void:
	# Hạt cỏ và bụi mịn bay ngang theo luồng gió.
	for i in range(particle_count):
		var p := _particle_position(i, 48.0, 470.0, 260.0)
		draw_line(p, p + Vector2(7.0, sin(_elapsed + float(i)) * 1.5), Color(0.84, 0.77, 0.48, 0.32), 1.2, true)

func _draw_swamp() -> void:
	# Bọt khí và túi khí độc xanh nhạt nổi lên chậm.
	for i in range(12):
		var phase := _elapsed * (0.32 + float(i % 4) * 0.08) + float(i) * 2.4
		var p := Vector2(sin(phase) * (170.0 + float(i % 3) * 70.0), fposmod(float(i) * 57.0 - _elapsed * 12.0, 520.0) - 260.0)
		var pulse := 0.5 + 0.5 * sin(phase * 1.7)
		draw_circle(p, 9.0 + pulse * 7.0, Color(0.43, 0.76, 0.43, 0.035))
		draw_arc(p, 3.0 + pulse * 2.0, 0.0, TAU, 12, Color(0.65, 0.86, 0.56, 0.25), 1.2)

func _draw_cavern() -> void:
	# Bụi đá rơi từ trần hang và ánh khoáng vật lấp lánh.
	for i in range(particle_count):
		var p := _particle_position(i, 9.0, 420.0, 280.0)
		var alpha := 0.18 + 0.12 * sin(_elapsed * 1.4 + float(i))
		draw_circle(p, 1.0 + float(i % 3) * 0.45, Color(0.78, 0.77, 0.68, alpha))
	for i in range(5):
		var phase := _elapsed * 1.1 + float(i) * 1.7
		var p := Vector2(sin(phase * 0.7) * (100.0 + float(i) * 48.0), cos(phase) * 170.0)
		draw_circle(p, 2.0, Color(0.64, 0.83, 0.91, 0.45))

func _draw_frost() -> void:
	# Tuyết rơi nhiều lớp, bông gần camera lớn và chậm hơn.
	for i in range(particle_count + 14):
		var p := _particle_position(i, 25.0 + float(i % 5) * 5.0, 450.0, 310.0)
		var drift := sin(_elapsed * 1.3 + float(i) * 0.8) * 8.0
		var radius := 1.0 + float(i % 4) * 0.45
		draw_line(p, p + Vector2(drift, 4.0 + radius), Color(0.88, 0.95, 1.0, 0.58), 1.0, true)
		draw_circle(p, radius, Color(0.94, 0.98, 1.0, 0.66))

func _draw_heartland() -> void:
	# Phấn hoa thưa và đom đóm nhẹ quanh vùng bộ lạc.
	for i in range(14):
		var phase := _elapsed * 0.35 + float(i) * 2.1
		var p := Vector2(sin(phase) * (110.0 + float(i % 4) * 65.0), cos(phase * 0.8) * (80.0 + float(i % 3) * 55.0))
		draw_circle(p, 1.5 + 0.8 * absf(sin(phase)), Color(0.95, 0.84, 0.51, 0.32))
