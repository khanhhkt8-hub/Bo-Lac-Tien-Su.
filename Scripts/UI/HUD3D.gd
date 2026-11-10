extends CanvasLayer
class_name HUD3D

const BUTTON_SIZE := Vector2(76.0, 68.0)
var _buttons: Dictionary = {}

func _ready() -> void:
	_build_controls()

func _build_controls() -> void:
	var panel := PanelContainer.new()
	panel.name = "MovementPad"
	panel.anchor_left = 0.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = 18.0
	panel.offset_top = -178.0
	panel.offset_right = 260.0
	panel.offset_bottom = -18.0
	panel.modulate = Color(1.0, 1.0, 1.0, 0.82)
	add_child(panel)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 5)
	grid.add_theme_constant_override("v_separation", 5)
	panel.add_child(grid)
	_add_spacer(grid)
	_add_move_button(grid, "▲", "ui_up")
	_add_spacer(grid)
	_add_move_button(grid, "◀", "ui_left")
	_add_move_button(grid, "▼", "ui_down")
	_add_move_button(grid, "▶", "ui_right")
	var hint := Label.new()
	hint.text = "KÉO MÀN HÌNH ĐỂ XOAY CAMERA"
	hint.anchor_left = 0.5
	hint.anchor_right = 0.5
	hint.anchor_top = 1.0
	hint.anchor_bottom = 1.0
	hint.offset_left = -150.0
	hint.offset_right = 150.0
	hint.offset_top = -42.0
	hint.offset_bottom = -14.0
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 13)
	add_child(hint)

func _add_spacer(parent: GridContainer) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = BUTTON_SIZE
	parent.add_child(spacer)

func _add_move_button(parent: GridContainer, label_text: String, action: String) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override("font_size", 28)
	button.button_down.connect(func(): Input.action_press(action))
	button.button_up.connect(func(): Input.action_release(action))
	parent.add_child(button)
	_buttons[action] = button

func _exit_tree() -> void:
	for action in _buttons:
		Input.action_release(str(action))
