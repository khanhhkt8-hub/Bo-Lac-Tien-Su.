extends CanvasModulate
class_name DayNightCycle

signal phase_changed(is_night: bool, day_number: int)

@export var day_duration: float = 240.0
@export var night_duration: float = 150.0
@export var transition_speed: float = 0.8

var is_night: bool = false
var day_number: int = 1
var phase_time_left: float = 240.0
var target_color: Color = Color.WHITE

func _ready() -> void:
	add_to_group("day_night_cycle")
	phase_time_left = day_duration
	color = Color.WHITE
	target_color = Color.WHITE

func _process(delta: float) -> void:
	phase_time_left -= delta
	color = color.lerp(target_color, clampf(delta * transition_speed, 0.0, 1.0))
	if phase_time_left <= 0.0:
		_change_phase()

func _change_phase() -> void:
	is_night = not is_night
	if is_night:
		phase_time_left = night_duration
		target_color = Color(0.38, 0.43, 0.68, 1.0)
	else:
		day_number += 1
		phase_time_left = day_duration
		target_color = Color.WHITE
	phase_changed.emit(is_night, day_number)

func get_phase_text() -> String:
	return "ĐÊM" if is_night else "NGÀY"

func get_time_report() -> String:
	var duration := night_duration if is_night else day_duration
	var elapsed := maxi(0, int(duration - phase_time_left))
	var game_minutes := int(float(elapsed) / maxf(1.0, duration) * 720.0)
	var start_hour := 18 if is_night else 6
	var hour := start_hour + int(float(game_minutes) / 60.0)
	var minute := game_minutes % 60
	return "NGÀY %d • %s • %02d:%02d" % [day_number, get_phase_text(), hour % 24, minute]
