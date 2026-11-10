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
var _leader_label: Label
var _day_night_label: Label
var _day_night_cycle: Node
var _day_night_refresh: float = 0.0
var _raid_director: Node
var _tribe_control: Node
var _rts_camera: Camera2D
var _camera_drag_active := false

func _ready() -> void:
	_player = get_node_or_null(player_path)
	_tribe_control = get_node_or_null("../TribeControlSystem")
	_rts_camera = get_node_or_null("../Camera2D") as Camera2D
	var panel := PanelContainer.new()
	panel.position = Vector2(12, 54)
	panel.custom_minimum_size = Vector2(350, 270)
	panel.size = Vector2(350, 270)
	panel.visible = false
	add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(338, 258)
	scroll.size = Vector2(338, 258)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(column)
	var menu_button := Button.new()
	menu_button.text = "☰ BỘ LẠC"
	menu_button.position = Vector2(12, 12)
	menu_button.custom_minimum_size = Vector2(132, 38)
	menu_button.pressed.connect(func() -> void:
		panel.visible = not panel.visible
		menu_button.text = "ĐÓNG MENU" if panel.visible else "☰ BỘ LẠC"
	)
	add_child(menu_button)
	_stats_label = Label.new()
	_stats_label.text = "Máu: -- | Đói: -- | Khát: --"
	column.add_child(_stats_label)
	_region_label = Label.new()
	_region_label.text = "Khu vực: Đồng bằng bộ lạc"
	_region_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_region_label)
	_leader_label = Label.new()
	_leader_label.text = "Tộc trưởng: đang cập nhật..."
	column.add_child(_leader_label)
	_day_night_cycle = get_node_or_null("../DayNightCycle")
	_raid_director = get_node_or_null("../BarbarianRaidDirector")
	if _raid_director != null:
		if _raid_director.has_signal("raid_warning") and not _raid_director.raid_warning.is_connected(_on_raid_warning):
			_raid_director.raid_warning.connect(_on_raid_warning)
		if _raid_director.has_signal("raid_started") and not _raid_director.raid_started.is_connected(_on_raid_started):
			_raid_director.raid_started.connect(_on_raid_started)
		if _raid_director.has_signal("intruder_detected") and not _raid_director.intruder_detected.is_connected(_on_intruder_detected):
			_raid_director.intruder_detected.connect(_on_intruder_detected)
	_day_night_label = Label.new()
	_day_night_label.text = "NGÀY 1 • ĐANG CẬP NHẬT"
	column.add_child(_day_night_label)
	_refresh_day_night_label()
	var leadership_button := Button.new()
	leadership_button.text = "HỘI ĐỒNG TỘC TRƯỞNG"
	leadership_button.pressed.connect(_on_show_leadership_pressed)
	column.add_child(leadership_button)
	if TribePopulation != null:
		if not TribePopulation.leader_changed.is_connected(_on_tribe_leader_changed):
			TribePopulation.leader_changed.connect(_on_tribe_leader_changed)
		_refresh_leader_label()
	var needs_row := HBoxContainer.new()
	column.add_child(needs_row)
	var morale_button := Button.new()
	morale_button.text = "TINH THẦN BỘ LẠC"
	morale_button.pressed.connect(_on_morale_report_pressed)
	needs_row.add_child(morale_button)
	var needs_button := Button.new()
	needs_button.text = "NHU CẦU BỘ LẠC"
	needs_button.pressed.connect(_on_tribe_needs_pressed)
	needs_row.add_child(needs_button)
	var capture_button := Button.new()
	capture_button.text = "THU PHỤC TÙ BINH GẦN ĐÂY"
	capture_button.pressed.connect(_on_capture_prisoner_pressed)
	column.add_child(capture_button)
	var treatment_button := Button.new()
	treatment_button.text = "CHỮA THƯƠNG BỘ LẠC"
	treatment_button.pressed.connect(_on_treat_tribe_pressed)
	needs_row.add_child(treatment_button)
	var supply_button := Button.new()
	supply_button.text = "CẤP THỨC ĂN + NƯỚC"
	supply_button.pressed.connect(_on_supply_tribe_pressed)
	needs_row.add_child(supply_button)
	_inventory_label = Label.new()
	_inventory_label.text = "Túi đồ: trống"
	column.add_child(_inventory_label)
	var tribe_control_row := HBoxContainer.new()
	column.add_child(tribe_control_row)
	var select_all_button := Button.new()
	select_all_button.text = "CHỌN CẢ BỘ LẠC"
	select_all_button.pressed.connect(_on_select_all_tribe_pressed)
	tribe_control_row.add_child(select_all_button)
	var area_select_button := Button.new()
	area_select_button.text = "CHỌN VÙNG"
	area_select_button.pressed.connect(_on_selection_area_pressed.bind(area_select_button))
	tribe_control_row.add_child(area_select_button)
	var move_order_button := Button.new()
	move_order_button.text = "DI CHUYỂN"
	move_order_button.pressed.connect(_on_move_order_pressed)
	tribe_control_row.add_child(move_order_button)
	var follow_button := Button.new()
	follow_button.text = "THEO TÔI"
	follow_button.pressed.connect(_on_follow_tribe_pressed)
	tribe_control_row.add_child(follow_button)
	var tribe_attack_button := Button.new()
	tribe_attack_button.text = "BỘ LẠC TẤN CÔNG"
	tribe_attack_button.pressed.connect(_on_tribe_attack_pressed)
	tribe_control_row.add_child(tribe_attack_button)
	var rally_flag_button := Button.new()
	rally_flag_button.text = "ĐẶT CỜ TẬP HỢP"
	rally_flag_button.pressed.connect(_on_set_rally_flag_pressed)
	tribe_control_row.add_child(rally_flag_button)
	var rally_button := Button.new()
	rally_button.text = "TẬP HỢP VỀ CỜ"
	rally_button.pressed.connect(_on_rally_to_flag_pressed)
	tribe_control_row.add_child(rally_button)
	var camera_button := Button.new()
	camera_button.text = "KÉO BẢN ĐỒ"
	camera_button.pressed.connect(_on_camera_drag_toggle_pressed.bind(camera_button))
	tribe_control_row.add_child(camera_button)
	var focus_button := Button.new()
	focus_button.text = "VỀ TRUNG TÂM"
	focus_button.pressed.connect(_on_camera_focus_pressed)
	tribe_control_row.add_child(focus_button)
	var squad_row := HBoxContainer.new()
	column.add_child(squad_row)
	_add_squad_button(squad_row, "CHIẾN BINH", "warrior")
	_add_squad_button(squad_row, "THỢ SĂN", "hunter")
	_add_squad_button(squad_row, "TRINH SÁT", "scout")
	_add_squad_button(squad_row, "HÁI LƯỢM", "gatherer")
	_add_squad_button(squad_row, "NÔNG DÂN", "farmer")
	_add_squad_button(squad_row, "THỢ CHẾ TÁC", "crafter")
	var add_squad_row := HBoxContainer.new()
	column.add_child(add_squad_row)
	_add_additive_squad_button(add_squad_row, "＋ CHIẾN BINH", "warrior")
	_add_additive_squad_button(add_squad_row, "＋ THỢ SĂN", "hunter")
	var support_button := Button.new()
	support_button.text = "CHỌN HẬU CẦN"
	support_button.pressed.connect(_on_select_support_pressed)
	add_squad_row.add_child(support_button)
	var add_support_button := Button.new()
	add_support_button.text = "＋ HẬU CẦN"
	add_support_button.pressed.connect(_on_add_support_pressed)
	add_squad_row.add_child(add_support_button)
	var clear_selection_button := Button.new()
	clear_selection_button.text = "BỎ CHỌN"
	clear_selection_button.pressed.connect(_on_clear_tribe_selection_pressed)
	squad_row.add_child(clear_selection_button)
	var scout_row := HBoxContainer.new()
	column.add_child(scout_row)
	var scout_button := Button.new()
	scout_button.text = "GIAO NHIỆM VỤ TRINH SÁT"
	scout_button.pressed.connect(_on_scout_mode_pressed.bind(scout_button))
	scout_row.add_child(scout_button)
	var scout_report_button := Button.new()
	scout_report_button.text = "BÁO CÁO TRINH SÁT"
	scout_report_button.pressed.connect(_on_scout_report_pressed)
	scout_row.add_child(scout_report_button)
	var combat_row := HBoxContainer.new()
	column.add_child(combat_row)
	var attack_button := Button.new()
	attack_button.text = "TẤN CÔNG"
	attack_button.pressed.connect(_on_attack_pressed)
	combat_row.add_child(attack_button)
	var relic_skill_button := Button.new()
	relic_skill_button.text = "KỸ NĂNG DI VẬT"
	relic_skill_button.pressed.connect(_on_relic_skill_pressed)
	combat_row.add_child(relic_skill_button)
	var patrol_button := Button.new()
	patrol_button.text = "TUẦN TRA"
	patrol_button.pressed.connect(_on_patrol_pressed.bind(patrol_button))
	combat_row.add_child(patrol_button)
	var hold_position_button := Button.new()
	hold_position_button.text = "GIỮ VỊ TRÍ"
	hold_position_button.pressed.connect(_on_hold_position_pressed)
	combat_row.add_child(hold_position_button)
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
	var awaken_button := Button.new()
	awaken_button.text = "THỨC TỈNH THẦN THÚ"
	awaken_button.pressed.connect(_on_awaken_god_beast_pressed)
	column.add_child(awaken_button)
	var leader_button := Button.new()
	leader_button.text = "PHONG THÚ CHÚA"
	leader_button.pressed.connect(_on_appoint_pack_leader_pressed)
	column.add_child(leader_button)
	var command_row := HBoxContainer.new()
	column.add_child(command_row)
	var attack_order_button := Button.new()
	attack_order_button.text = "THÚ TẤN CÔNG"
	attack_order_button.pressed.connect(_on_companion_attack_order_pressed)
	command_row.add_child(attack_order_button)
	var protect_order_button := Button.new()
	protect_order_button.text = "THÚ BẢO VỆ"
	protect_order_button.pressed.connect(_on_companion_protect_order_pressed)
	command_row.add_child(protect_order_button)
	var skill_button := Button.new()
	skill_button.text = "KỸ NĂNG ĐÀN THÚ"
	skill_button.pressed.connect(_on_companion_combat_summary_pressed)
	column.add_child(skill_button)
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
	var egg_row := HBoxContainer.new()
	column.add_child(egg_row)
	var egg_status_button := Button.new()
	egg_status_button.text = "XEM Ổ TRỨNG"
	egg_status_button.pressed.connect(_on_egg_status_pressed)
	egg_row.add_child(egg_status_button)
	var hatch_button := Button.new()
	hatch_button.text = "ẤP / NỞ TRỨNG"
	hatch_button.pressed.connect(_on_hatch_egg_pressed)
	egg_row.add_child(hatch_button)
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
	var companion_gear_row := HBoxContainer.new()
	column.add_child(companion_gear_row)
	_add_craft_button(companion_gear_row, "Giáp thú", "companion_armor")
	_add_craft_button(companion_gear_row, "Bùa nanh", "companion_fang")
	var equip_gear_button := Button.new()
	equip_gear_button.text = "TRANG BỊ THÚ"
	equip_gear_button.pressed.connect(_on_equip_companion_gear_pressed)
	companion_gear_row.add_child(equip_gear_button)
	var relic_row_one := HBoxContainer.new()
	column.add_child(relic_row_one)
	_add_craft_button(relic_row_one, "Rìu Ma Mút", "relic_mammoth_axe")
	_add_craft_button(relic_row_one, "Kiếm Răng Hổ", "relic_saber_blade")
	_add_craft_button(relic_row_one, "Thương Sấm", "relic_thunder_spear")
	var relic_row_two := HBoxContainer.new()
	column.add_child(relic_row_two)
	_add_craft_button(relic_row_two, "Vuốt Đầm Lầy", "relic_swamp_claw")
	_add_craft_button(relic_row_two, "Chùy Hang", "relic_cavern_hammer")
	_add_craft_button(relic_row_two, "Cung Băng", "relic_frost_bow")
	var survival_gear_row := HBoxContainer.new()
	column.add_child(survival_gear_row)
	_add_craft_button(survival_gear_row, "Áo da", "fur_cloak")
	_add_craft_button(survival_gear_row, "Thuốc giải", "herbal_antidote")
	_add_craft_button(survival_gear_row, "Đuốc", "torch")
	_create_mobile_movement_pad()
	_create_quick_action_buttons()
	_create_tribe_management_button()
	if ScoutSystem != null and not ScoutSystem.status_changed.is_connected(_on_scout_status_changed):
		ScoutSystem.status_changed.connect(_on_scout_status_changed)

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


func _process(delta: float) -> void:
	_day_night_refresh += delta
	if _day_night_refresh >= 1.0:
		_day_night_refresh = 0.0
		_refresh_day_night_label()

func _on_raid_warning(seconds_left: int) -> void:
	if _craft_status != null:
		_craft_status.text = "BÁO ĐỘNG! Man rợ đang áp sát. Còn %d giây để tập hợp chiến binh và bảo vệ kho!" % seconds_left

func _on_raid_started(raider_count: int) -> void:
	if _craft_status != null:
		_craft_status.text = "ĐỘT KÍCH BAN ĐÊM! Có %d kẻ địch xuất hiện. Hãy bảo vệ bộ lạc!" % raider_count

func _on_intruder_detected(distance: int) -> void:
	if _craft_status != null:
		_craft_status.text = "CẢNH BÁO XÂM NHẬP! Man rợ đã lọt vào vùng bộ lạc, cách cờ tập hợp %d m. Hãy điều chiến binh!" % distance

func _refresh_day_night_label() -> void:
	if _day_night_label == null:
		return
	if _day_night_cycle != null and _day_night_cycle.has_method("get_time_report"):
		_day_night_label.text = str(_day_night_cycle.call("get_time_report"))
	else:
		_day_night_label.text = "Chu kỳ ngày đêm chưa sẵn sàng"

func _on_morale_report_pressed() -> void:
	if TribePopulation != null:
		_craft_status.text = TribePopulation.get_morale_report()

func _on_tribe_needs_pressed() -> void:
	if TribePopulation != null:
		_craft_status.text = TribePopulation.get_needs_report()

func _on_capture_prisoner_pressed() -> void:
	if is_instance_valid(_tribe_control) and _tribe_control.has_method("capture_nearest_prisoner"):
		_craft_status.text = _tribe_control.capture_nearest_prisoner()

func _on_treat_tribe_pressed() -> void:
	if TribePopulation != null:
		_craft_status.text = TribePopulation.treat_wounded_residents()

func _on_supply_tribe_pressed() -> void:
	if _inventory == null or TribePopulation == null:
		_craft_status.text = "Hệ thống hậu cần chưa sẵn sàng."
		return
	var food_items := ["food", "fish", "fruit", "chicken", "duck", "eggs", "meat"]
	var food_given := 0
	for item_id in food_items:
		var available := _inventory.get_amount(item_id)
		if available <= 0:
			continue
		var amount := mini(available, 5 - food_given)
		if amount > 0 and _inventory.remove_item(item_id, amount):
			food_given += amount
		if food_given >= 5:
			break
	var water_given := mini(_inventory.get_amount("water"), 5)
	if water_given > 0:
		_inventory.remove_item("water", water_given)
	TribePopulation.add_tribe_supplies(food_given, water_given)
	if food_given == 0 and water_given == 0:
		_craft_status.text = "Túi đồ không có thức ăn hoặc nước để tiếp tế."
	else:
		_craft_status.text = "Đã tiếp tế %d phần thức ăn và %d phần nước cho bộ lạc." % [food_given, water_given]

func _on_show_leadership_pressed() -> void:
	if TribePopulation == null:
		return
	var dialog := AcceptDialog.new()
	dialog.title = "HỘI ĐỒNG TỘC TRƯỞNG"
	dialog.dialog_text = TribePopulation.get_leadership_report()
	dialog.min_size = Vector2i(560, 520)
	add_child(dialog)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.popup_centered()

func _refresh_leader_label() -> void:
	if _leader_label == null or TribePopulation == null:
		return
	var leader: Dictionary = TribePopulation.get_leader()
	if leader.is_empty():
		_leader_label.text = "Tộc trưởng: chưa có người kế nhiệm"
		return
	_leader_label.text = "TỘC TRƯỞNG: %s | Tuổi %d" % [str(leader.get("name", "Ẩn danh")), int(leader.get("age", 0))]

func _on_tribe_leader_changed(_old_leader: Dictionary, new_leader: Dictionary) -> void:
	_refresh_leader_label()
	if _craft_status != null:
		if new_leader.is_empty():
			_craft_status.text = "Bộ lạc chưa tìm được người kế nhiệm tộc trưởng!"
		else:
			_craft_status.text = "%s đã được chọn làm tộc trưởng mới." % str(new_leader.get("name", "Người kế nhiệm"))

func _create_quick_action_buttons() -> void:
	_add_quick_action("ĐÁNH", Vector2(-150, -138), _on_attack_pressed)
	_add_quick_action("NHẶT", Vector2(-78, -138), _on_gather_pressed)
	_add_quick_action("THUẦN", Vector2(-150, -76), _on_tame_pressed)
	_add_quick_action("BẮN", Vector2(-78, -76), _on_shoot_pressed)

func _add_quick_action(label: String, offset: Vector2, callback: Callable) -> void:
	var button := Button.new()
	button.text = label
	button.custom_minimum_size = Vector2(68, 54)
	button.anchor_left = 1.0
	button.anchor_right = 1.0
	button.anchor_top = 1.0
	button.anchor_bottom = 1.0
	button.offset_left = offset.x
	button.offset_top = offset.y
	button.offset_right = offset.x + 68.0
	button.offset_bottom = offset.y + 54.0
	button.pressed.connect(callback)
	add_child(button)

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

func _add_squad_button(parent: HBoxContainer, label: String, role_id: String) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(_on_select_squad_pressed.bind(role_id, label))
	parent.add_child(button)

func _add_additive_squad_button(parent: HBoxContainer, label: String, role_id: String) -> void:
	var button := Button.new()
	button.text = label
	button.pressed.connect(_on_add_squad_pressed.bind(role_id, label))
	parent.add_child(button)

func _on_select_squad_pressed(role_id: String, label: String) -> void:
	if _tribe_control == null:
		return
	var count := int(_tribe_control.call("select_role", role_id))
	_craft_status.text = "Đã chọn %s: %d người. Lệnh mới chỉ áp dụng cho nhóm đang chọn." % [label, count]

func _on_add_squad_pressed(role_id: String, label: String) -> void:
	if _tribe_control == null:
		return
	var count := int(_tribe_control.call("select_role_additive", role_id))
	_craft_status.text = "Đã thêm %s vào nhóm chọn chung. Tổng: %d người." % [label, count]

func _on_select_support_pressed() -> void:
	if _tribe_control == null:
		return
	var count := int(_tribe_control.call("select_support_roles", false))
	_craft_status.text = "Đã chọn hậu cần (hái lượm, nông dân, chế tác): %d người." % count

func _on_add_support_pressed() -> void:
	if _tribe_control == null:
		return
	var count := int(_tribe_control.call("select_support_roles", true))
	_craft_status.text = "Đã thêm hậu cần vào nhóm chọn chung. Tổng: %d người." % count

func _on_clear_tribe_selection_pressed() -> void:
	if _tribe_control == null:
		return
	_tribe_control.call("clear_selection")
	_craft_status.text = "Đã bỏ chọn toàn bộ đơn vị."

func _on_select_all_tribe_pressed() -> void:
	if _tribe_control != null:
		var count: int = _tribe_control.select_all()
		_craft_status.text = "Đã chọn %d thành viên bộ lạc" % count

func _on_selection_area_pressed(button: Button) -> void:
	if _tribe_control == null:
		return
	var enabled := not bool(_tribe_control.get("selection_area_mode"))
	_tribe_control.call("set_selection_area_mode", enabled)
	button.text = "THOÁT CHỌN VÙNG" if enabled else "CHỌN VÙNG"
	_craft_status.text = "Kéo ngón tay để khoanh vùng chọn nhiều dân làng." if enabled else "Đã thoát chế độ chọn vùng."

func _on_move_order_pressed() -> void:
	if _tribe_control != null:
		_tribe_control.set_move_mode(true)
		_craft_status.text = "Chạm vị trí trên bản đồ để ra lệnh di chuyển cho nhóm đã chọn"

func _on_follow_tribe_pressed() -> void:
	if _tribe_control != null:
		var count: int = _tribe_control.order_all_follow_player()
		_craft_status.text = "%d thành viên đang tập hợp theo bạn" % count

func _on_tribe_attack_pressed() -> void:
	if _tribe_control != null:
		var count: int = _tribe_control.order_all_attack()
		_craft_status.text = "%d thành viên chuyển sang đội hình chiến đấu" % count

func _on_scout_mode_pressed(button: Button) -> void:
	if _tribe_control == null:
		return
	var enabled := not bool(_tribe_control.get("scout_mode"))
	if enabled and int(_tribe_control.call("get_selected_count")) == 0:
		_craft_status.text = "Hãy chọn tiểu đội TRINH SÁT trước."
		return
	_tribe_control.call("set_scout_mode", enabled)
	button.text = "CHỌN ĐIỂM ĐẾN" if enabled else "GIAO NHIỆM VỤ TRINH SÁT"
	_craft_status.text = "Chạm vào vùng chưa khám phá để cử trinh sát đến đó." if enabled else "Đã hủy nhiệm vụ trinh sát."

func _on_scout_report_pressed() -> void:
	if ScoutSystem != null:
		_craft_status.text = ScoutSystem.get_latest_report_text()

func _on_scout_status_changed(message: String) -> void:
	if _craft_status != null:
		_craft_status.text = message

func _on_patrol_pressed(button: Button) -> void:
	if _tribe_control == null:
		return
	var enabled := not bool(_tribe_control.get("patrol_mode"))
	if enabled and int(_tribe_control.call("get_selected_count")) == 0:
		_craft_status.text = "Hãy chọn một nhóm người trưởng thành trước khi vẽ tuyến tuần tra."
		return
	_tribe_control.call("set_patrol_mode", enabled)
	button.text = "ĐANG VẼ TUYẾN" if enabled else "TUẦN TRA"
	_craft_status.text = "Chạm 2 điểm trên bản đồ để tạo tuyến tuần tra khép kín." if enabled else "Đã hủy vẽ tuyến tuần tra."

func _on_hold_position_pressed() -> void:
	if _tribe_control == null:
		return
	var count: int = _tribe_control.order_selected_hold_position()
	if count == 0:
		_craft_status.text = "Hãy chọn nhóm người trưởng thành trước."
	else:
		_craft_status.text = "%d người giữ vị trí và tự chống trả kẻ địch gần đó." % count

func _on_set_rally_flag_pressed() -> void:
	if _tribe_control != null:
		_tribe_control.set_rally_mode(true)
		_craft_status.text = "Chạm lên bản đồ để cắm hoặc dời CỜ TẬP HỢP"

func _on_rally_to_flag_pressed() -> void:
	if _tribe_control == null:
		return
	var count: int = _tribe_control.rally_all_to_flag()
	if count == 0:
		_craft_status.text = "Chưa có cờ tập hợp. Hãy chọn ĐẶT CỜ TẬP HỢP trước"
	else:
		_craft_status.text = "%d thành viên đang tập hợp về lá cờ" % count


func _on_camera_drag_toggle_pressed(button: Button) -> void:
	if _rts_camera == null:
		return
	_camera_drag_active = not _camera_drag_active
	_rts_camera.set_drag_enabled(_camera_drag_active)
	button.text = "THOÁT KÉO BẢN ĐỒ" if _camera_drag_active else "KÉO BẢN ĐỒ"
	_craft_status.text = "Đang kéo bản đồ: vuốt màn hình để di chuyển camera" if _camera_drag_active else "Đã tắt chế độ kéo bản đồ"

func _on_camera_focus_pressed() -> void:
	if _rts_camera == null or _player == null:
		return
	_rts_camera.focus_world_position(_player.global_position)
	_craft_status.text = "Camera đã trở về trung tâm bộ lạc"

func _on_attack_pressed() -> void:
	if _player != null and _player.has_method("attack_nearby"):
		if not _player.attack_nearby():
			_craft_status.text = "Không có kẻ địch trong tầm hoặc đang hồi chiêu"

func _on_relic_skill_pressed() -> void:
	if _player != null and _player.has_method("use_relic_weapon_skill"):
		_craft_status.text = _player.use_relic_weapon_skill()

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

func _on_appoint_pack_leader_pressed() -> void:
	if _player != null and _player.has_method("appoint_pack_leader"):
		_craft_status.text = _player.appoint_pack_leader()

func _on_awaken_god_beast_pressed() -> void:
	if _player != null and _player.has_method("awaken_nearby_god_beast"):
		_craft_status.text = _player.awaken_nearby_god_beast()

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


func _on_companion_attack_order_pressed() -> void:
	if _player != null and _player.has_method("command_companions_attack"):
		_craft_status.text = _player.command_companions_attack()

func _on_companion_protect_order_pressed() -> void:
	if _player != null and _player.has_method("command_companions_protect"):
		_craft_status.text = _player.command_companions_protect()

func _on_companion_combat_summary_pressed() -> void:
	if _player != null and _player.has_method("get_companion_combat_summary"):
		_craft_status.text = _player.get_companion_combat_summary()


func _on_equip_companion_gear_pressed() -> void:
	if _player != null and _player.has_method("equip_nearby_companion_gear"):
		_craft_status.text = _player.equip_nearby_companion_gear()


func _on_egg_status_pressed() -> void:
	if _player != null and _player.has_method("get_egg_summary"):
		_craft_status.text = _player.get_egg_summary()


func _on_hatch_egg_pressed() -> void:
	if _player != null and _player.has_method("hatch_ready_egg"):
		_craft_status.text = _player.hatch_ready_egg()
