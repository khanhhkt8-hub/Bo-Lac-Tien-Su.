extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")

var _stats_label: Label
var _inventory_label: Label
var _craft_status: Label
var _player: Node
var _stats: SurvivalStats
var _inventory: InventorySystem
var _crafting: CraftingSystem

func _ready() -> void:
	_player = get_node_or_null(player_path)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(350, 178)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	_stats_label = Label.new()
	_stats_label.text = "Máu: -- | Đói: -- | Khát: --"
	column.add_child(_stats_label)
	_inventory_label = Label.new()
	_inventory_label.text = "Túi đồ: trống"
	column.add_child(_inventory_label)
	var combat_row := HBoxContainer.new()
	column.add_child(combat_row)
	var attack_button := Button.new()
	attack_button.text = "TẤN CÔNG"
	attack_button.pressed.connect(_on_attack_pressed)
	combat_row.add_child(attack_button)
	var gather_button := Button.new()
	gather_button.text = "THU THẬP TÀI NGUYÊN"
	gather_button.pressed.connect(_on_gather_pressed)
	column.add_child(gather_button)
	_craft_status = Label.new()
	_craft_status.text = "Rìu: 3 gỗ + 2 đá | Giáo: 2 gỗ + 1 đá | Lửa: 5 gỗ + 3 đá"
	_craft_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_craft_status)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	_add_craft_button(buttons, "Rìu đá", "stone_axe")
	_add_craft_button(buttons, "Giáo đá", "stone_spear")
	_add_craft_button(buttons, "Đống lửa", "campfire")
	_create_mobile_movement_pad()

	if _player != null:
		_stats = _player.get("survival_stats") as SurvivalStats
		_inventory = _player.get("inventory") as InventorySystem
		_crafting = _player.get("crafting") as CraftingSystem
		if _stats != null:
			_stats.stats_changed.connect(_on_stats_changed)
			_on_stats_changed(_stats.health, _stats.hunger, _stats.thirst)
		if _inventory != null:
			_inventory.inventory_changed.connect(_on_inventory_changed)
			_on_inventory_changed(_inventory.items)

func _create_mobile_movement_pad() -> void:
	_add_move_button("↑", "ui_up", Vector2(92, -190))
	_add_move_button("←", "ui_left", Vector2(20, -125))
	_add_move_button("↓", "ui_down", Vector2(92, -125))
	_add_move_button("→", "ui_right", Vector2(164, -125))

func _add_move_button(title: String, action: String, offset: Vector2) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(64, 60)
	button.anchor_left = 0.0
	button.anchor_right = 0.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset.x
	button.offset_top = offset.y
	button.offset_right = offset.x + 64.0
	button.offset_bottom = offset.y + 60.0
	button.button_down.connect(_on_move_button_down.bind(action))
	button.button_up.connect(_on_move_button_up.bind(action))
	add_child(button)

func _on_move_button_down(action: String) -> void:
	Input.action_press(action)

func _on_move_button_up(action: String) -> void:
	Input.action_release(action)

func _on_attack_pressed() -> void:
	if _player != null and _player.has_method("attack_nearby"):
		if not _player.attack_nearby():
			_craft_status.text = "Không có kẻ địch trong tầm hoặc đang hồi chiêu"

func _on_gather_pressed() -> void:
	if _player != null and _player.has_method("gather_nearby"):
		if not _player.gather_nearby():
			_craft_status.text = "Hãy đến gần một điểm tài nguyên"

func _add_craft_button(parent: HBoxContainer, title: String, item_id: String) -> void:
	var button := Button.new()
	button.text = title
	button.pressed.connect(_on_craft_pressed.bind(item_id))
	parent.add_child(button)

func _on_craft_pressed(item_id: String) -> void:
	if _crafting == null:
		_craft_status.text = "Chế tạo chưa sẵn sàng"
	elif _crafting.craft(item_id):
		_craft_status.text = "Đã chế tạo: " + item_id
	else:
		_craft_status.text = "Thiếu nguyên liệu: " + _crafting.get_recipe_text(item_id)

func _on_stats_changed(health: float, hunger: float, thirst: float) -> void:
	_stats_label.text = "Máu: %d | Đói: %d | Khát: %d" % [roundi(health), roundi(hunger), roundi(thirst)]

func _on_inventory_changed(items: Dictionary) -> void:
	if items.is_empty():
		_inventory_label.text = "Túi đồ: trống"
		return
	var parts: PackedStringArray = []
	for item_id in items:
		parts.append("%s: %d" % [str(item_id), int(items[item_id])])
	_inventory_label.text = "Túi đồ: " + " | ".join(parts)
