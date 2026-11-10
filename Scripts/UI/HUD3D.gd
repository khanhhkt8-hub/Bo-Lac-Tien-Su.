extends CanvasLayer
class_name HUD3D

const BUTTON_SIZE := Vector2(76.0, 68.0)
var _buttons: Dictionary = {}

func _ready() -> void:
	add_to_group("hud_3d")
	_build_controls()
	_build_inventory_label()

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

var _inventory_label: Label

func _build_inventory_label() -> void:
	_inventory_label = Label.new()
	_inventory_label.anchor_left = 1.0
	_inventory_label.anchor_right = 1.0
	_inventory_label.offset_left = -290.0
	_inventory_label.offset_right = -16.0
	_inventory_label.offset_top = 18.0
	_inventory_label.offset_bottom = 110.0
	_inventory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_inventory_label.add_theme_font_size_override("font_size", 17)
	_inventory_label.text = "TÚI ĐỒ: trống"
	add_child(_inventory_label)
	var gather_button := Button.new()
	gather_button.text = "THU THẬP"
	gather_button.anchor_left = 1.0
	gather_button.anchor_top = 1.0
	gather_button.anchor_right = 1.0
	gather_button.anchor_bottom = 1.0
	gather_button.offset_left = -174.0
	gather_button.offset_top = -112.0
	gather_button.offset_right = -18.0
	gather_button.offset_bottom = -30.0
	gather_button.add_theme_font_size_override("font_size", 18)
	gather_button.pressed.connect(func(): Input.action_press("interact"); Input.action_release("interact"))
	add_child(gather_button)

func show_inventory(items: Dictionary) -> void:
	if not is_instance_valid(_inventory_label):
		return
	var lines: PackedStringArray = []
	for key in items:
		lines.append("%s: %d" % [str(key).to_upper(), int(items[key])])
	_inventory_label.text = "TÚI ĐỒ\n" + "\n".join(lines)
