extends Node
## Offline tribe population and life-cycle simulation.
## Time is simulated: one in-game year passes every 20 real minutes by default.

signal population_changed(total: int, children: int, adults: int, elders: int)
signal resident_died(resident_name: String)
signal child_born(resident_name: String)
signal resident_became_adult(resident_name: String, resident_id: int)
signal resident_became_elder(resident_name: String, resident_id: int)
signal resident_became_ill(resident_name: String, resident_id: int)
signal leader_changed(old_leader: Dictionary, new_leader: Dictionary)

const SAVE_PATH := "user://bo_lac_population.cfg"
const SECONDS_PER_YEAR := 1200.0
const ADULT_AGE := 18
const ELDER_AGE := 60
const MAX_AGE := 90
const LEADER_RETIREMENT_AGE := 70

var residents: Array[Dictionary] = []
var _year_accumulator: float = 0.0
var _needs_accumulator: float = 0.0
const NEEDS_TICK_SECONDS := 60.0
var _next_id: int = 1
var leader_id: int = -1
var _load_leader_id: int = -1
var leadership_history: Array[Dictionary] = []

func _ready() -> void:
	load_population()
	if residents.is_empty():
		leader_id = add_resident("Tộc trưởng đời thứ nhất", 32, "male", "chieftain")
		add_resident("Bạn đời", 29, "female")
	else:
		leader_id = _load_leader_id
	if get_leader().is_empty():
		elect_new_leader()
	_emit_population()

func _process(delta: float) -> void:
	_needs_accumulator += delta
	if _needs_accumulator >= NEEDS_TICK_SECONDS:
		_needs_accumulator -= NEEDS_TICK_SECONDS
		_advance_resident_needs()
	_year_accumulator += delta
	while _year_accumulator >= SECONDS_PER_YEAR:
		_year_accumulator -= SECONDS_PER_YEAR
		_advance_one_year()

func add_resident(resident_name: String, age: int, sex: String, role: String = "villager", parent_a_id: int = -1, parent_b_id: int = -1) -> int:
	if age < 0 or sex not in ["male", "female"]:
		return -1
	var resident_id := _next_id
	_next_id += 1
	var inherited_traits: Dictionary = {}
	if role == "child":
		inherited_traits = _inherit_traits_from_parents(parent_a_id, parent_b_id)
	else:
		inherited_traits = _generate_resident_traits()
	residents.append({
		"id": resident_id, "name": resident_name, "age": age,
		"sex": sex, "role": role, "partner_id": -1,
		"health": 100.0, "food": 20, "water": 20, "strength": 10, "stamina": 10, "morale": 70.0, "experience": 0, "skills": {}, "traits": inherited_traits, "alive": true, "in_daycare": false, "illness": false
	})
	_emit_population()
	save_population()
	return resident_id


func _generate_resident_traits() -> Dictionary:
	var traits := {
		"strength": randi_range(1, 10),
		"agility": randi_range(1, 10),
		"intelligence": randi_range(1, 10),
		"endurance": randi_range(1, 10),
		"perception": randi_range(1, 10)
	}
	# Một số cá nhân có thiên hướng nổi bật hoặc điểm yếu rõ rệt.
	var trait_names: Array = traits.keys()
	var favored: String = str(trait_names[randi_range(0, trait_names.size() - 1)])
	traits[favored] = mini(10, int(traits[favored]) + 2)
	return traits


func _inherit_traits_from_parents(first_parent_id: int = -1, second_parent_id: int = -1) -> Dictionary:
	var first_parent := _find_resident(first_parent_id)
	var second_parent := _find_resident(second_parent_id)
	if first_parent.is_empty() or second_parent.is_empty():
		return _generate_resident_traits()
	var first_traits: Dictionary = first_parent.get("traits", {})
	var second_traits: Dictionary = second_parent.get("traits", {})
	var inherited := {}
	for trait_name in ["strength", "agility", "intelligence", "endurance", "perception"]:
		var first := int(first_traits.get(trait_name, 5))
		var second := int(second_traits.get(trait_name, 5))
		inherited[trait_name] = clampi(roundi((first + second) / 2.0) + randi_range(-1, 1), 1, 10)
	return inherited

func get_trait_report(resident_id: int) -> String:
	var person := get_resident(resident_id)
	if person.is_empty():
		return "Không tìm thấy dân làng."
	var traits: Dictionary = person.get("traits", {})
	return "ĐẶC TÍNH: %s\\nSức mạnh: %d/10\\nNhanh nhẹn: %d/10\\nTrí tuệ: %d/10\\nSức bền: %d/10\\nQuan sát: %d/10" % [
		str(person.get("name", "Dân làng")),
		int(traits.get("strength", 5)),
		int(traits.get("agility", 5)),
		int(traits.get("intelligence", 5)),
		int(traits.get("endurance", 5)),
		int(traits.get("perception", 5))
	]

func recruit_migrant(resident_name: String, age: int, sex: String, role: String = "migrant") -> int:
	return add_resident(resident_name, age, sex, role)

func recruit_captive(resident_name: String, age: int = 20, sex: String = "male") -> int:
	var resident_id := add_resident(resident_name, age, sex, "captive_recruit")
	if resident_id >= 0:
		var person := get_resident(resident_id)
		person["morale"] = 35.0
		save_population()
	return resident_id

func get_leader() -> Dictionary:
	return _find_resident(leader_id)

func elect_new_leader() -> Dictionary:
	var previous := get_leader().duplicate(true)
	var candidates: Array[Dictionary] = []
	for person in residents:
		if not bool(person.get("alive", true)) or int(person.get("age", 0)) < ADULT_AGE:
			continue
		if int(person.get("id", -1)) == leader_id and int(person.get("age", 0)) >= LEADER_RETIREMENT_AGE:
			continue
		candidates.append(person)
	if candidates.is_empty():
		leader_id = -1
		if not previous.is_empty():
			leader_changed.emit(previous, {})
		save_population()
		return {}
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _leadership_score(a) > _leadership_score(b)
	)
	var chosen: Dictionary = candidates[0]
	leader_id = int(chosen.id)
	chosen["role"] = "chieftain"
	for person in residents:
		if int(person.get("id", -1)) != leader_id and str(person.get("role", "")) == "chieftain":
			person["role"] = "villager"
	if not previous.is_empty() and int(previous.get("id", -1)) != leader_id:
		var record := previous.duplicate(true)
		record["ended_at_age"] = int(previous.get("age", 0))
		leadership_history.append(record)
		if leadership_history.size() > 30:
			leadership_history.pop_front()
	leader_changed.emit(previous, chosen.duplicate(true))
	save_population()
	return chosen

func _leadership_score(person: Dictionary) -> float:
	var age := int(person.get("age", 18))
	var prime_age_bonus := 25.0 if age >= 25 and age <= 55 else 0.0
	var traits: Dictionary = person.get("traits", {})
	var wisdom_bonus := float(traits.get("intelligence", 5)) * 1.5
	var awareness_bonus := float(traits.get("perception", 5)) * 1.0
	return float(person.get("health", 0.0)) * 0.35 + float(person.get("strength", 0)) * 2.0 + float(person.get("stamina", 0)) * 1.5 + float(person.get("experience", 0)) * 2.5 + prime_age_bonus + wisdom_bonus + awareness_bonus

func get_leadership_report() -> String:
	var lines := PackedStringArray()
	var current := get_leader()
	if current.is_empty():
		lines.append("TỘC TRƯỞNG HIỆN TẠI: Chưa có")
	else:
		lines.append("TỘC TRƯỞNG HIỆN TẠI")
		lines.append("%s | %d tuổi | Sức khỏe %d" % [str(current.get("name", "Ẩn danh")), int(current.get("age", 0)), roundi(float(current.get("health", 0.0)))])
	lines.append("")
	lines.append("ỨNG VIÊN KẾ NHIỆM (xếp theo năng lực)")
	var candidates: Array[Dictionary] = []
	for person in residents:
		if not bool(person.get("alive", true)) or int(person.get("age", 0)) < ADULT_AGE or int(person.get("id", -1)) == leader_id:
			continue
		candidates.append(person)
	candidates.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return _leadership_score(a) > _leadership_score(b)
	)
	if candidates.is_empty():
		lines.append("Chưa có ứng viên trưởng thành đủ điều kiện.")
	else:
		for index in range(mini(5, candidates.size())):
			var person: Dictionary = candidates[index]
			lines.append("%d. %s | %d tuổi | Điểm %.1f" % [index + 1, str(person.get("name", "Ẩn danh")), int(person.get("age", 0)), _leadership_score(person)])
	lines.append("")
	lines.append("LỊCH SỬ CÁC ĐỜI TỘC TRƯỞNG")
	if leadership_history.is_empty():
		lines.append("Chưa có lần chuyển giao quyền lãnh đạo.")
	else:
		for index in range(leadership_history.size() - 1, -1, -1):
			var former: Dictionary = leadership_history[index]
			lines.append("%d. %s | kết thúc nhiệm kỳ ở tuổi %d" % [leadership_history.size() - index, str(former.get("name", "Ẩn danh")), int(former.get("ended_at_age", former.get("age", 0)))])
	return "\n".join(lines)

func pair_residents(first_id: int, second_id: int) -> bool:
	var first := _find_resident(first_id)
	var second := _find_resident(second_id)
	if first.is_empty() or second.is_empty():
		return false
	if int(first.age) < ADULT_AGE or int(second.age) < ADULT_AGE:
		return false
	if first.sex == second.sex or int(first.partner_id) != -1 or int(second.partner_id) != -1:
		return false
	first.partner_id = second_id
	second.partner_id = first_id
	save_population()
	return true

func set_daycare(resident_id: int, enrolled: bool) -> bool:
	var resident := _find_resident(resident_id)
	if resident.is_empty() or int(resident.age) >= ADULT_AGE:
		return false
	resident.in_daycare = enrolled
	save_population()
	return true

func get_population_summary() -> Dictionary:
	var summary := {"total": 0, "children": 0, "adults": 0, "elders": 0}
	for person in residents:
		if not person.alive:
			continue
		summary.total += 1
		var age := int(person.age)
		if age < ADULT_AGE:
			summary.children += 1
		elif age < ELDER_AGE:
			summary.adults += 1
		else:
			summary.elders += 1
	return summary


func _advance_resident_needs() -> void:
	var changed := false
	var has_childcare_worker := false
	if TribeJobSystem != null:
		for assigned_job in TribeJobSystem.assignments.values():
			if str(assigned_job) == "caregiver":
				has_childcare_worker = true
				break
	# Trẻ em được xét nhu cầu trước để ưu tiên nguồn lương thực và nước khi khan hiếm.
	var needs_order: Array[Dictionary] = []
	for resident in residents:
		if bool(resident.get("alive", true)):
			needs_order.append(resident)
	needs_order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var age_a := int(a.get("age", 18))
		var age_b := int(b.get("age", 18))
		var child_a := age_a < ADULT_AGE
		var child_b := age_b < ADULT_AGE
		if child_a != child_b:
			return child_a
		if age_a != age_b:
			return age_a < age_b
		return float(a.get("health", 100.0)) < float(b.get("health", 100.0))
	)
	for person in needs_order:
		var food := int(person.get("food", 0))
		var water := int(person.get("water", 0))
		var fed := false
		var hydrated := false
		var morale := float(person.get("morale", 70.0))
		if food > 0:
			person["food"] = food - 1
			fed = true
		elif _consume_stockpile_food():
			person["food"] = 0
			fed = true
		else:
			person["health"] = maxf(0.0, float(person.get("health", 100.0)) - 3.0)
			changed = true
		if water > 0:
			person["water"] = water - 1
			hydrated = true
		elif TribeJobSystem != null and TribeJobSystem.raid_stockpile("water", 1) > 0:
			person["water"] = 0
			hydrated = true
		else:
			person["health"] = maxf(0.0, float(person.get("health", 100.0)) - 5.0)
			changed = true
		if not fed:
			morale -= 4.0
		if not hydrated:
			morale -= 5.0
		if fed and hydrated:
			morale += 1.5
		if int(person.get("age", 18)) < 6 and (has_childcare_worker or bool(person.get("in_daycare", false))):
			morale += 2.0
		if bool(person.get("illness", false)):
			morale -= 1.0
		person["morale"] = clampf(morale, 0.0, 100.0)
		# Healthy, well-fed villagers slowly recover. Illness needs herbs to cure.
		if fed and hydrated:
			var resting_at_night := false
			var cycles := get_tree().get_nodes_in_group("day_night_cycle")
			if not cycles.is_empty():
				resting_at_night = bool(cycles[0].get("is_night"))
			if resting_at_night:
				person["stamina"] = mini(10, int(person.get("stamina", 0)) + 2)
			else:
				person["stamina"] = mini(10, int(person.get("stamina", 0)) + 1)
			if bool(person.get("illness", false)):
				person["health"] = maxf(0.0, float(person.get("health", 100.0)) - 2.0)
				if TribeJobSystem != null and TribeJobSystem.raid_stockpile("herbs", 1) > 0:
					person["illness"] = false
					person["health"] = minf(100.0, float(person.get("health", 0.0)) + 8.0)
				changed = true
			else:
				var old_health := float(person.get("health", 100.0))
				var recovery := 2.0 if resting_at_night else 1.0
				if int(person.get("age", 18)) < 6 and (has_childcare_worker or bool(person.get("in_daycare", false))):
					recovery += 1.0
				person["health"] = minf(100.0, old_health + recovery)
				if float(person["health"]) != old_health:
					changed = true
				if float(person.get("health", 100.0)) <= 60.0 and randf() < 0.04:
					person["illness"] = true
					resident_became_ill.emit(str(person.get("name", "Dân làng")), int(person.get("id", -1)))
					changed = true
		if float(person.get("health", 100.0)) <= 0.0:
			person["alive"] = false
			resident_died.emit(str(person.get("name", "Dân làng")))
			changed = true
	var leader := get_leader()
	if leader.is_empty():
		elect_new_leader()
	if changed:
		_emit_population()
	save_population()


func _consume_stockpile_food() -> bool:
	if TribeJobSystem == null:
		return false
	for resource_id in ["food", "meat", "fish", "fruit", "berries", "chicken", "duck", "eggs"]:
		if TribeJobSystem.raid_stockpile(resource_id, 1) > 0:
			return true
	return false

func add_tribe_supplies(food_amount: int, water_amount: int) -> int:
	# Chia theo vòng từng đơn vị để người đứng cuối danh sách không bị bỏ đói.
	var supplied := 0
	var remaining_food := maxi(0, food_amount)
	var remaining_water := maxi(0, water_amount)
	while remaining_food > 0 or remaining_water > 0:
		var distributed_this_round := false
		for person in residents:
			if not bool(person.get("alive", true)):
				continue
			if remaining_food > 0 and int(person.get("food", 0)) < 20:
				person["food"] = int(person.get("food", 0)) + 1
				remaining_food -= 1
				supplied += 1
				distributed_this_round = true
			if remaining_water > 0 and int(person.get("water", 0)) < 20:
				person["water"] = int(person.get("water", 0)) + 1
				remaining_water -= 1
				distributed_this_round = true
		if not distributed_this_round:
			break
	save_population()
	return supplied

func get_needs_report() -> String:
	var hungry := 0
	var thirsty := 0
	var critical := 0
	var sick := 0
	for person in residents:
		if not bool(person.get("alive", true)):
			continue
		if int(person.get("food", 0)) <= 3:
			hungry += 1
		if int(person.get("water", 0)) <= 3:
			thirsty += 1
		if float(person.get("health", 100.0)) <= 35.0:
			critical += 1
		if bool(person.get("illness", false)):
			sick += 1
	var summary := get_population_summary()
	var stock_food := 0
	var stock_water := 0
	if TribeJobSystem != null:
		for resource_id in ["food", "meat", "fish", "fruit", "berries", "chicken", "duck", "eggs"]:
			stock_food += int(TribeJobSystem.stockpile.get(resource_id, 0))
		stock_water = int(TribeJobSystem.stockpile.get("water", 0))
	return "DÂN SỐ: %d\\nThiếu lương thực: %d\\nThiếu nước: %d\\nĐang mắc bệnh: %d\\nSức khỏe nguy cấp: %d\\nKho thức ăn: %d | Kho nước: %d\\n\\nDân đủ ăn uống sẽ hồi 1 máu mỗi phút. Người bệnh cần thảo dược trong kho để chữa." % [int(summary.total), hungry, thirsty, sick, critical, stock_food, stock_water]

func _advance_one_year() -> void:
	var births: Array[Dictionary] = []
	for person in residents:
		if not bool(person.get("alive", true)):
			continue
		var previous_age := int(person.get("age", 0))
		person["age"] = previous_age + 1
		var current_age := int(person.age)
		var resident_name := str(person.get("name", "Dân làng"))
		var resident_id := int(person.get("id", -1))
		# Phát tín hiệu mốc tuổi để giao diện và hệ thống nghề có thể cập nhật.
		if previous_age < ADULT_AGE and current_age >= ADULT_AGE:
			resident_became_adult.emit(resident_name, resident_id)
		if previous_age < ELDER_AGE and current_age >= ELDER_AGE:
			resident_became_elder.emit(resident_name, resident_id)
		# Người già có nguy cơ qua đời tăng dần theo tuổi; tuổi 90 là giới hạn tối đa.
		var elder_death_chance := clampf(0.025 + float(current_age - ELDER_AGE) * 0.012, 0.025, 0.30)
		if current_age >= MAX_AGE or (current_age >= ELDER_AGE and randf() < elder_death_chance):
			person["alive"] = false
			person["health"] = 0.0
			resident_died.emit(resident_name)
			if resident_id == leader_id:
				elect_new_leader()
			continue
		if current_age >= 20 and current_age <= 40 and str(person.get("sex", "")) == "female" and int(person.get("partner_id", -1)) != -1:
			if randf() < 0.18:
				births.append(person)
	# Người cao tuổi truyền kinh nghiệm cho tối đa hai thành viên trẻ mỗi năm.
	var elders: Array[Dictionary] = []
	var learners: Array[Dictionary] = []
	for person in residents:
		if not bool(person.get("alive", true)):
			continue
		if int(person.get("age", 0)) >= ELDER_AGE:
			elders.append(person)
		elif int(person.get("age", 0)) >= 6 and int(person.get("age", 0)) < ELDER_AGE:
			learners.append(person)
	learners.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("experience", 0)) < int(b.get("experience", 0))
	)
	var learner_index := 0
	for elder in elders:
		for lesson in range(2):
			if learner_index >= learners.size():
				break
			var learner: Dictionary = learners[learner_index]
			learner["experience"] = mini(100, int(learner.get("experience", 0)) + 2)
			learner["morale"] = clampf(float(learner.get("morale", 70.0)) + 1.0, 0.0, 100.0)
			learner_index += 1
	var current_leader := get_leader()
	if current_leader.is_empty() or int(current_leader.get("age", 0)) >= LEADER_RETIREMENT_AGE:
		elect_new_leader()
	for mother in births:
		var baby_name := "Em bé %d" % _next_id
		add_resident(baby_name, 0, "male" if randf() < 0.5 else "female", "child", int(mother.get("id", -1)), int(mother.get("partner_id", -1)))
		child_born.emit(baby_name)
	_emit_population()
	save_population()


func apply_combat_damage(resident_id: int, damage: float) -> float:
	var person := get_resident(resident_id)
	if person.is_empty():
		return 0.0
	var old_health := float(person.get("health", 100.0))
	var new_health := maxf(0.0, old_health - maxf(0.0, damage))
	person["health"] = new_health
	person["morale"] = clampf(float(person.get("morale", 70.0)) - maxf(2.0, damage * 0.45), 0.0, 100.0)
	if new_health <= 0.0:
		person["alive"] = false
		resident_died.emit(str(person.get("name", "Dân làng")))
		if resident_id == leader_id:
			elect_new_leader()
	_emit_population()
	save_population()
	return new_health

func treat_wounded_residents() -> String:
	var treated := 0
	var herbs_used := 0
	for person in residents:
		if not bool(person.get("alive", true)):
			continue
		var health := float(person.get("health", 100.0))
		if health >= 100.0 and not bool(person.get("illness", false)):
			continue
		if TribeJobSystem == null or TribeJobSystem.raid_stockpile("herbs", 1) <= 0:
			break
		person["health"] = minf(100.0, health + 35.0)
		person["illness"] = false
		treated += 1
		herbs_used += 1
	if treated > 0:
		save_population()
		_emit_population()
	if treated == 0:
		return "Không có người cần chữa hoặc kho đã hết thảo dược."
	return "Đã chữa %d người, dùng %d bó thảo dược." % [treated, herbs_used]


func hold_tribe_festival() -> String:
	if TribeJobSystem == null:
		return "Kho lương thực chưa sẵn sàng."
	var food_ids := ["food", "meat", "fish", "chicken", "duck", "eggs"]
	var fruit_ids := ["fruit", "berries"]
	var food_total := 0
	var fruit_total := 0
	for resource_id in food_ids:
		food_total += int(TribeJobSystem.stockpile.get(resource_id, 0))
	for resource_id in fruit_ids:
		fruit_total += int(TribeJobSystem.stockpile.get(resource_id, 0))
	if food_total < 5 or fruit_total < 3:
		return "Chưa đủ lễ vật. Cần 5 phần thức ăn/thịt/cá và 3 trái cây/quả mọng trong kho."
	var food_left := 5
	for resource_id in food_ids:
		if food_left <= 0:
			break
		food_left -= TribeJobSystem.raid_stockpile(resource_id, food_left)
	var fruit_left := 3
	for resource_id in fruit_ids:
		if fruit_left <= 0:
			break
		fruit_left -= TribeJobSystem.raid_stockpile(resource_id, fruit_left)
	var participants := 0
	for person in residents:
		if not bool(person.get("alive", true)):
			continue
		person["morale"] = clampf(float(person.get("morale", 70.0)) + 12.0, 0.0, 100.0)
		participants += 1
	save_population()
	_emit_population()
	return "LỄ HỘI BỘ LẠC THÀNH CÔNG! %d người tham gia, tinh thần mỗi người tăng 12 điểm. Đã dùng 5 phần thức ăn và 3 phần trái cây." % participants

func get_morale_report() -> String:
	var total := 0
	var sum_morale := 0.0
	var low := 0
	var very_low := 0
	for person in residents:
		if not bool(person.get("alive", true)):
			continue
		total += 1
		var morale := float(person.get("morale", 70.0))
		sum_morale += morale
		if morale < 50.0:
			low += 1
		if morale < 25.0:
			very_low += 1
	if total == 0:
		return "Bộ lạc hiện không còn cư dân."
	var average := sum_morale / float(total)
	var status := "Ổn định"
	if average < 35.0:
		status = "Khủng hoảng tinh thần"
	elif average < 55.0:
		status = "Tinh thần suy giảm"
	elif average >= 80.0:
		status = "Tinh thần rất tốt"
	return "TINH THẦN BỘ LẠC: %s\nTrung bình: %.0f/100\nTinh thần thấp: %d người\nNguy cơ suy sụp: %d người\n\nĐảm bảo thức ăn, nước uống và bảo vệ dân làng để duy trì tinh thần." % [status, average, low, very_low]

func get_wounded_count() -> int:
	var count := 0
	for person in residents:
		if bool(person.get("alive", true)) and float(person.get("health", 100.0)) < 100.0:
			count += 1
	return count

func get_resident(resident_id: int) -> Dictionary:
	return _find_resident(resident_id)

func _find_resident(resident_id: int) -> Dictionary:
	for person in residents:
		if int(person.id) == resident_id and person.alive:
			return person
	return {}

func _emit_population() -> void:
	var summary := get_population_summary()
	population_changed.emit(summary.total, summary.children, summary.adults, summary.elders)

func save_population() -> void:
	var config := ConfigFile.new()
	config.set_value("tribe", "residents", residents)
	config.set_value("tribe", "next_id", _next_id)
	config.set_value("tribe", "leader_id", leader_id)
	config.set_value("tribe", "leadership_history", leadership_history)
	config.save(SAVE_PATH)

func load_population() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: Array = config.get_value("tribe", "residents", [])
	residents.clear()
	for person in saved:
		if person is Dictionary:
			if not person.has("food"):
				person["food"] = 20
			if not person.has("water"):
				person["water"] = 20
			if not person.has("health"):
				person["health"] = 100.0
			if not person.has("illness"):
				person["illness"] = false
			if not person.has("experience"):
				person["experience"] = 0
			if not person.has("skills") or not (person["skills"] is Dictionary):
				person["skills"] = {}
			if not person.has("traits") or not (person["traits"] is Dictionary):
				person["traits"] = _generate_resident_traits()
			residents.append(person)
	_next_id = int(config.get_value("tribe", "next_id", residents.size() + 1))
	_load_leader_id = int(config.get_value("tribe", "leader_id", -1))
	var saved_history: Array = config.get_value("tribe", "leadership_history", [])
	leadership_history.clear()
	for record in saved_history:
		if record is Dictionary:
			leadership_history.append(record)
	leader_id = _load_leader_id
