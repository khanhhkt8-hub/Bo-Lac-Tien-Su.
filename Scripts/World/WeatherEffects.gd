extends Node2D
class_name WeatherEffects

@export var weather_cycle_seconds: float = 105.0
@export var rain_duration: float = 28.0
@export var drop_count: int = 72

var _timer: float = 0.0
var _rain_active: bool = false
var _rain_strength: float = 0.0
var _elapsed: float = 0.0
var _wind: float = 0.0
var _player: Node2D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_timer = weather_cycle_seconds * 0.55
	set_process(true)

func _process(delta: float) -> void:
	_elapsed += delta
	_timer -= delta
	if _timer <= 0.0:
		_rain_active = not _rain_active
		_timer = rain_duration if _rain_active else weather_cycle_seconds - rain_duration
	_wind = sin(_elapsed * 0.17) * 0.55 + 0.65
	var target := 0.72 if _rain_active else 0.0
	_rain_strength = move_toward(_rain_strength, target, delta * 0.22)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player != null:
		global_position = _player.global_position
	queue_redraw()

func _draw() -> void:
	if _rain_strength <= 0.01:
		return
	# Màn mưa mỏng quanh camera, không tạo hàng trăm node riêng.
	for i in range(drop_count):
		var seed := float(i) * 37.17
		var x := fposmod(seed * 19.0 + _elapsed * (105.0 + float(i % 7) * 9.0) * _wind, 920.0) - 460.0
		var y := fposmod(seed * 31.0 + _elapsed * (330.0 + float(i % 5) * 24.0), 620.0) - 310.0
		var alpha := _rain_strength * (0.24 + 0.12 * sin(seed))
		draw_line(Vector2(x, y), Vector2(x - 5.0 * _wind, y + 17.0), Color(0.72, 0.84, 0.91, alpha), 1.15, true)
	# Màn sương thấp, mờ và trôi chậm ở rìa tầm nhìn.
	for i in range(7):
		var seed := float(i) * 2.4
		var x := sin(_elapsed * 0.08 + seed) * 370.0
		var y := cos(_elapsed * 0.06 + seed * 1.7) * 230.0
		var fog_alpha := _rain_strength * 0.035
		_draw_soft_mist(Vector2(x, y), 100.0 + float(i % 3) * 28.0, fog_alpha)

func _draw_soft_mist(center: Vector2, radius: float, alpha: float) -> void:
	for layer in range(3):
		var r := radius * (1.0 - float(layer) * 0.22)
		draw_circle(center + Vector2(float(layer) * 13.0, 0.0), r, Color(0.76, 0.84, 0.84, alpha * (1.0 - float(layer) * 0.2)))
