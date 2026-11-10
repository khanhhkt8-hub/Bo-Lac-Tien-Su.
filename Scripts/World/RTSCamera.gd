extends Camera2D
## Free RTS camera: middle mouse drag, optional touch-drag mode, and wheel zoom.

@export var zoom_step := 0.10
@export var min_zoom := 0.55
@export var max_zoom := 1.65
var drag_enabled := false
var _mouse_dragging := false
var _last_pointer := Vector2.ZERO
var _touch_points: Dictionary = {}
var _last_pinch_distance := 0.0

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	zoom = Vector2.ONE

func set_drag_enabled(enabled: bool) -> void:
	drag_enabled = enabled
	_mouse_dragging = false

func focus_world_position(target: Vector2) -> void:
	global_position = target

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_mouse_dragging = event.pressed
			_last_pointer = event.position
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(1.0 + zoom_step)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(1.0 - zoom_step)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _mouse_dragging:
		var pointer_delta: Vector2 = event.position - _last_pointer
		global_position -= pointer_delta / zoom.x
		_last_pointer = event.position
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenTouch:
		if event.pressed:
			_touch_points[event.index] = event.position
			if _touch_points.size() == 2:
				_last_pinch_distance = _get_pinch_distance()
			else:
				_last_pointer = event.position
			get_viewport().set_input_as_handled()
		else:
			_touch_points.erase(event.index)
			if _touch_points.size() < 2:
				_last_pinch_distance = 0.0
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_touch_points[event.index] = event.position
		if _touch_points.size() >= 2:
			var pinch_distance := _get_pinch_distance()
			if _last_pinch_distance > 0.0 and pinch_distance > 0.0:
				_apply_zoom(pinch_distance / _last_pinch_distance)
			_last_pinch_distance = pinch_distance
		elif drag_enabled:
			global_position -= event.relative / zoom.x
		get_viewport().set_input_as_handled()

func _apply_zoom(multiplier: float) -> void:
	var next_zoom := clampf(zoom.x * multiplier, min_zoom, max_zoom)
	zoom = Vector2(next_zoom, next_zoom)

func _get_pinch_distance() -> float:
	if _touch_points.size() < 2:
		return 0.0
	var points: Array = _touch_points.values()
	return Vector2(points[0]).distance_to(Vector2(points[1]))
