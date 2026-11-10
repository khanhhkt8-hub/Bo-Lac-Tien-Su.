extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")

var _stats_label: Label
var _inventory_label: Label
var _craft_status: Label
var _player: Node
var _stats: SurvivalStats
var _inventory: InventorySystem
var _crafting: CraftingSystem
var _tribe_panel: PanelContainer
var _region_label: Label

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
	_region_label = Label.new()
	_region_label.text = "Khu vực: Đồng bằng bộ lạc"
	_region_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_region_label)
	_inventory_label = Label.new()
	_inventory_label.text = "Túi đồ: trống"
	column.add_child(_inventory_label)
	var combat_row := HBoxContainer.new()
	column.add_child(combat_row)
	var attack_button := Button.new()
	attack_button.text = "TẤN CÔNG"
	attack_button.pressed.connect(_on_attack_pressed)
	combat_row.add_child(attack_button)
	var mount_row := HBoxContainer.new()
	column.add_child(mount_row)
	var mount_button := Button.new()
	mount_button.text = "CƯỠI / XUỐNG THÚ"
	mount_button.pressed.connect(_on_mount_pressed)
	mount_row.add_child(mount_button)
	var upgrade_button := Button.new()
	upgrade_button.text = "NÂNG CẤP THÚ"
	upgrade_button.pressed.connect(_on_upgrade_companion_pressed)
	mount_row.add_child(upgrade_button)
	var care_row := HBoxContainer.new()
	column.add_child(care_row)
	var feed_button := Button.new()
	feed_button.text = "CHO THÚ ĂN / HỒI MÁU"
	feed_button.pressed.connect(_on_feed_companion_pressed)
	care_row.add_child(feed_button)
	var herd_button := Button.new()
	herd_button.text = "XEM ĐÀN THÚ"
	herd_button.pressed.connect(_on_herd_summary_pressed)
	care_row.add_child(herd_button)
	var breed_button := Button.new()
	breed_button.text = "LAI TẠO THÚ"
	breed_button.pressed.connect(_on_breed_companions_pressed)
	column.add_child(breed_button)
	var tame_button := Button.new()
	tame_button.text = "THUẦN HÓA THÚ"
	tame_button.pressed.connect(_on_tame_pressed)
	column.add_child(tame_button)
	var gather_button := Button.new()
	gather_button.text = "THU THẬP TÀI NGUYÊN"
	gather_button.pressed.connect(_on_gather_pressed)
	column.add_child(gather_button)
	_craft_status = Label.new()
	_craft_status.text = "Chế tạo: Rìu, giáo, cung, tên, lửa trại, trang bị sinh tồn"
	_craft_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_craft_status)
	var ranged_row := HBoxContainer.new()
	column.add_child(ranged_row)
	_add_craft_button(ranged_row, "Cung", "bow")
	_add_craft_button(ranged_row, "Tên x5", "arrows")
	var shoot_button := Button.new()
	shoot_button.text = "BẮN CUNG"
	shoot_button.pressed.connect(_on_shoot_pressed)
	ranged_row.add_child(shoot_button)
	var buttons := HBoxContainer.new()
	column.add_child(buttons)
	_add_craft_button(buttons, "Rìu đá", "stone_axe")
	_add_craft_button(buttons, "Giáo đá", "stone_spear")
	_add_craft_button(buttons, "Đống lửa", "campfire")
	var survival_gear_row := HBoxContainer.new()
	column.add_child(survival_gear_row)
	_add_craft_button(survival_gear_row, "Áo da", "fur_cloak")
	_add_craft_button(survival_gear_row, "Thuốc giải", "herbal_antidote")
	_add_craft_button(survival_gear_row, "Đuốc", "torch")
	_create_mobile_movement_pad()
	_create_tribe_management_button()

	if RegionSystem != null:
		RegionSystem.region_changed.connect(_on_region_changed)
		if not RegionSystem.current_region_id.is_empty():
			_on_region_changed(RegionSystem.current_region_id, RegionSystem.get_region_data(RegionSystem.current_region_id))
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

func _on_shoot_pressed() -> void:
	if _player != null and _player.has_method("shoot_arrow"):
		if not _player.shoot_arrow():
			_craft_status.text = "Cần cung, tên và mục tiêu trong tầm bắn"

func _on_tame_pressed() -> void:
	if _player != null and _player.has_method("tame_nearby_animal"):
		_craft_status.text = _player.tame_nearby_animal()

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

func _create_tribe_management_button() -> void:
	var button := Button.new()
	button.text = "BỘ LẠC"
	button.position = Vector2(-176, 16)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.offset_left = -176.0
	button.offset_top = 16.0
	button.offset_right = -16.0
	button.offset_bottom = 64.0
	button.pressed.connect(_toggle_tribe_panel)
	add_child(button)
	_tribe_panel = PanelContainer.new()
	_tribe_panel.set_script(load("res://Scripts/UI/TribeManagementPanel.gd"))
	_tribe_panel.position = Vector2(-326, 76)
	_tribe_panel.anchor_left = 1.0
	_tribe_panel.anchor_right = 1.0
	_tribe_panel.offset_left = -326.0
	_tribe_panel.offset_top = 76.0
	_tribe_panel.offset_right = -16.0
	_tribe_panel.offset_bottom = 420.0
	_tribe_panel.visible = false
	add_child(_tribe_panel)

func _toggle_tribe_panel() -> void:
	if _tribe_panel != null:
		_tribe_panel.visible = not _tribe_panel.visible

func _on_region_changed(region_id: String, data: Dictionary) -> void:
	if _region_label == null:
		return
	if region_id.is_empty() or data.is_empty():
		_region_label.text = "Khu vực: Vùng hoang dã chưa xác định"
		return
	var resources: Array = data.get("resources", [])
	var wildlife: Array = data.get("wildlife", [])
	var resource_text := ", ".join(PackedStringArray(resources))
	var wildlife_text := ", ".join(PackedStringArray(wildlife))
	var summary: Dictionary = RegionSystem.get_discovery_summary()
	_region_label.text = "Khu vực: %s | Nguy hiểm: %d/5 | Khí hậu: %s\nTài nguyên: %s\nThú đặc trưng: %s | Khám phá: %d/%d\nNguy cơ: %s" % [
		str(data.get("name", "Chưa rõ")),
		int(data.get("danger", 1)),
		str(data.get("climate", "Không rõ")),
		resource_text,
		wildlife_text,
		int(summary.get("discovered", 1)),
		int(summary.get("total", 6)),
		str(data.get("hazard", "Không rõ"))
	]


func _on_mount_pressed() -> void:
	if _player != null and _player.has_method("toggle_mount_nearby_animal"):
		_craft_status.text = _player.toggle_mount_nearby_animal()

func _on_upgrade_companion_pressed() -> void:
	if _player != null and _player.has_method("upgrade_nearby_companion"):
		_craft_status.text = _player.upgrade_nearby_companion()


func _on_breed_companions_pressed() -> void:
	if _player != null and _player.has_method("breed_nearby_companions"):
		_craft_status.text = _player.breed_nearby_companions()


func _on_feed_companion_pressed() -> void:
	if _player != null and _player.has_method("feed_nearby_companion"):
		_craft_status.text = _player.feed_nearby_companion()

func _on_herd_summary_pressed() -> void:
	if _player != null and _player.has_method("get_companion_herd_summary"):
		_craft_status.text = _player.get_companion_herd_summary()
