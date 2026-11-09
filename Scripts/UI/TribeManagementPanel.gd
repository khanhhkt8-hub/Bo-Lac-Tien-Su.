extends PanelContainer
## Mobile-friendly tribe management panel. Uses the offline autoload systems.

var _summary: Label
var _status: Label
var _selected_resident_index: int = 0
var _selected_house_id: int = -1
var _resident_ids: Array[int] = []
var _job_ids: Array[String] = ["hunter", "gatherer", "farmer", "crafter", "warrior"]
var _selected_job_index: int = 0

func _ready() -> void:
	custom_minimum_size = Vector2(300, 300)
	var column := VBoxContainer.new()
	add_child(column)
	var heading := Label.new()
	heading.text = "QUẢN LÝ BỘ LẠC"
	column.add_child(heading)
	_summary = Label.new()
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_summary)
	var resident_button := Button.new()
	resident_button.text = "ĐỔI DÂN LÀNG ĐANG CHỌN"
	resident_button.pressed.connect(_select_next_resident)
	column.add_child(resident_button)
	var create_button := Button.new()
	create_button.text = "DỰNG NHÀ MỚI"
	create_button.pressed.connect(_create_house)
	column.add_child(create_button)
	var upgrade_button := Button.new()
	upgrade_button.text = "NÂNG CẤP NHÀ ĐANG CHỌN"
	upgrade_button.pressed.connect(_upgrade_house)
	column.add_child(upgrade_button)
	var assign_button := Button.new()
	assign_button.text = "PHÂN CÔNG VÀO NHÀ"
	assign_button.pressed.connect(_assign_resident)
	column.add_child(assign_button)
	var materials_button := Button.new()
	materials_button.text = "ĐỔI 10 GỖ + 5 ĐÁ TỪ TÚI ĐỒ"
	materials_button.pressed.connect(_transfer_materials)
	column.add_child(materials_button)
	var job_button := Button.new()
	job_button.text = "ĐỔI NGHỀ CHO DÂN ĐANG CHỌN"
	job_button.pressed.connect(_assign_selected_job)
	column.add_child(job_button)
	var train_button := Button.new()
	train_button.text = "HUẤN LUYỆN DÂN LÀNG"
	train_button.pressed.connect(_train_resident)
	column.add_child(train_button)
	_status = Label.new()
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD
	column.add_child(_status)
	var close_button := Button.new()
	close_button.text = "ĐÓNG"
	close_button.pressed.connect(func(): visible = false)
	column.add_child(close_button)
	_refresh()

func _refresh() -> void:
	_resident_ids.clear()
	for person in TribePopulation.residents:
		if bool(person.get("alive", true)):
			_resident_ids.append(int(person.id))
	if _resident_ids.is_empty():
		_selected_resident_index = 0
	else:
		_selected_resident_index = clampi(_selected_resident_index, 0, _resident_ids.size() - 1)
	if _selected_house_id == -1 and not TribeHousingSystem.houses.is_empty():
		_selected_house_id = int(TribeHousingSystem.houses[0].id)
	var pop: Dictionary = TribePopulation.get_population_summary()
	var job_summary: Dictionary = TribeJobSystem.get_job_summary()
	var job_counts: Dictionary = job_summary.counts
	var stock: Dictionary = job_summary.stockpile
	var housing: Dictionary = TribeHousingSystem.get_housing_summary()
	var house_text := "Chưa có nhà"
	var house := _find_house(_selected_house_id)
	if not house.is_empty():
		house_text = "%s - cấp %d - %d/%d người" % [str(house.name), int(house.level), house.resident_ids.size(), int(house.capacity)]
	var resident_text := "Chưa chọn dân làng"
	if not _resident_ids.is_empty():
		var person := _find_resident(_resident_ids[_selected_resident_index])
		resident_text = "%s (#%d, %d tuổi)" % [str(person.name), int(person.id), int(person.age)]
	_summary.text = "Dân số: %d (trẻ %d / trưởng thành %d / cao tuổi %d)\nNhà: %d | Sức chứa: %d | Chưa phân nhà: %d\nĐang chọn: %s\nDân làng: %s\nGỗ: %d | Đá: %d\nNghề: Săn %d / Hái %d / Nông %d / Chế tác %d / Lính %d\nKho: Thịt %d, Quả %d, Lương thực %d, Dụng cụ %d" % [
		int(pop.total), int(pop.children), int(pop.adults), int(pop.elders),
		int(housing.houses), int(housing.capacity), int(housing.homeless),
		house_text, resident_text, TribeHousingSystem.wood, TribeHousingSystem.stone
	]

func _select_next_resident() -> void:
	if _resident_ids.is_empty():
		_set_status("Bộ lạc chưa có dân làng.")
		return
	_selected_resident_index = (_selected_resident_index + 1) % _resident_ids.size()
	_refresh()

func _create_house() -> void:
	_selected_house_id = TribeHousingSystem.create_house("Nhà bộ lạc %d" % (TribeHousingSystem.houses.size() + 1))
	_set_status("Đã dựng nhà cấp 1. Hãy chuyển gỗ và đá từ túi đồ để nâng cấp.")
	_refresh()

func _upgrade_house() -> void:
	if _selected_house_id < 0:
		_set_status("Chưa có nhà để nâng cấp.")
	elif TribeHousingSystem.upgrade_house(_selected_house_id):
		_set_status("Nâng cấp nhà thành công!")
	else:
		_set_status("Không đủ gỗ/đá hoặc nhà đã đạt cấp tối đa.")
	_refresh()

func _assign_resident() -> void:
	if _resident_ids.is_empty() or _selected_house_id < 0:
		_set_status("Cần có dân làng và nhà trước.")
		return
	var resident_id := _resident_ids[_selected_resident_index]
	if TribeHousingSystem.assign_resident(_selected_house_id, resident_id):
		_set_status("Đã phân công dân làng vào nhà.")
	else:
		_set_status("Nhà đã hết chỗ.")
	_refresh()

func _transfer_materials() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or player.get("inventory") == null:
		_set_status("Không tìm thấy túi đồ người chơi.")
		return
	var inventory: InventorySystem = player.inventory
	if inventory.get_amount("wood") < 10 or inventory.get_amount("stone") < 5:
		_set_status("Cần 10 gỗ và 5 đá trong túi đồ.")
		return
	inventory.remove_item("wood", 10)
	inventory.remove_item("stone", 5)
	TribeHousingSystem.add_materials(10, 5)
	_set_status("Đã chuyển 10 gỗ và 5 đá vào kho bộ lạc.")
	_refresh()

func _assign_selected_job() -> void:
	if _resident_ids.is_empty():
		_set_status("Không có dân làng để phân nghề.")
		return
	var resident_id := _resident_ids[_selected_resident_index]
	var job_id := _job_ids[_selected_job_index]
	if TribeJobSystem.assign_job(resident_id, job_id):
		_set_status("Đã phân công: " + TribeJobSystem.get_job_name(job_id) + ". Sản lượng được cộng mỗi 30 giây.")
	else:
		_set_status("Chỉ cư dân trưởng thành mới được nhận nghề.")
	_selected_job_index = (_selected_job_index + 1) % _job_ids.size()
	_refresh()

func _train_resident() -> void:
	if _resident_ids.is_empty():
		_set_status("Không có dân làng để huấn luyện.")
		return
	var resident_id := _resident_ids[_selected_resident_index]
	if TribeTrainingSystem.start_training(resident_id):
		_set_status("Đã bắt đầu huấn luyện 90 giây. Tốn 5 lương thực.")
	else:
		_set_status("Không thể huấn luyện: cần người trưởng thành, đủ lương thực và không đang tập.")
	_refresh()

func _find_house(house_id: int) -> Dictionary:
	for house in TribeHousingSystem.houses:
		if int(house.id) == house_id:
			return house
	return {}

func _find_resident(resident_id: int) -> Dictionary:
	for person in TribePopulation.residents:
		if int(person.id) == resident_id and bool(person.get("alive", true)):
			return person
	return {}

func _set_status(message: String) -> void:
	_status.text = message
