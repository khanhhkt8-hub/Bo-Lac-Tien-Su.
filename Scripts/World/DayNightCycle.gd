extends CanvasModulate
class_name DayNightCycle

signal phase_changed(is_night: bool, day_number: int)

@export var day_duration: float = 240.0
@export var night_duration: float = 150.0
@export var transition_speed: float = 1.35

var is_night: bool = false
var day_number: int = 1
var phase_time_left: float = 240.0
var target_color: Color = Color.WHITE

func _ready() -> void:
	add_to_group("day_night_cycle")
	phase_time_left = day_duration
	target_color = _get_ambient_color()
	color = target_color

func _process(delta: float) -> void:
	phase_time_left -= delta
	target_color = _get_ambient_color()
	color = color.lerp(target_color, clampf(delta * transition_speed, 0.0, 1.0))
	if phase_time_left <= 0.0:
		_change_phase()

# Ánh sáng đổi mềm theo từng đoạn thời gian, không chỉ bật/tắt ngày và đêm.
func _get_ambient_color() -> Color:
	var duration := night_duration if is_night else day_duration
	var progress := 1.0 - clampf(phase_time_left / maxf(1.0, duration), 0.0, 1.0)
	if is_night:
		if progress < 0.18:
			return Color(0.48, 0.43, 0.62, 1.0).lerp(Color(0.29, 0.34, 0.56, 1.0), progress / 0.18)
		if progress > 0.78:
			return Color(0.29, 0.34, 0.56, 1.0).lerp(Color(0.48, 0.43, 0.62, 1.0), (progress - 0.78) / 0.22)
		return Color(0.29, 0.34, 0.56, 1.0)
	if progress < 0.18:
		return Color(0.82, 0.62, 0.48, 1.0).lerp(Color(1.0, 0.96, 0.82, 1.0), progress / 0.18)
	if progress > 0.78:
		return Color(1.0, 0.96, 0.82, 1.0).lerp(Color(0.88, 0.63, 0.48, 1.0), (progress - 0.78) / 0.22)
	return Color(1.0, 0.96, 0.82, 1.0)

func _change_phase() -> void:
	is_night = not is_night
	if is_night:
		phase_time_left = night_duration
	else:
		day_number += 1
		phase_time_left = day_duration
	target_color = _get_ambient_color()
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
