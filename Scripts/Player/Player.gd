extends CharacterBody2D

const ArrowProjectile = preload("res://Scripts/Player/ArrowProjectile.gd")
const ANIMAL_SCENE: PackedScene = preload("res://Scenes/PrehistoricAnimal.tscn")
const COMPANION_SAVE_PATH := "user://bo_lac_companions.cfg"

@export var move_speed: float = 220.0
@export var gather_distance: float = 76.0

var survival_stats: SurvivalStats
var inventory: InventorySystem
var crafting: CraftingSystem
var attack_cooldown_left: float = 0.0
var relic_skill_cooldown_left: float = 0.0
const RELIC_SKILL_COOLDOWN := 8.0
var current_region_id := ""
var hazard_damage_timer := 0.0
var antidote_seconds := 0.0
var mounted_animal: PrehistoricAnimal
var _loading_companions := false
var _companion_save_timer := 0.0
var incubating_eggs: Array[Dictionary] = []
var walk_phase := 0.0
var attack_flash := 0.0
@export var attack_cooldown: float = 0.55
@export var attack_range: float = 72.0

func _ready() -> void:
	add_to_group("player")
	survival_stats = SurvivalStats.new()
	survival_stats.name = "SurvivalStats"
	add_child(survival_stats)
	inventory = InventorySystem.new()
	inventory.name = "Inventory"
	add_child(inventory)
	crafting = CraftingSystem.new()
	crafting.name = "Crafting"
	add_child(crafting)
	crafting.setup(inventory)
	if RegionSystem != null:
		RegionSystem.region_changed.connect(_on_region_changed)
		if not RegionSystem.current_region_id.is_empty():
			_on_region_changed(RegionSystem.current_region_id, RegionSystem.get_region_data(RegionSystem.current_region_id))
	_load_companions()

func _physics_process(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	attack_flash = maxf(0.0, attack_flash - delta)
	if attack_flash > 0.0:
		queue_redraw()
	if velocity.length_squared() > 10.0:
		walk_phase += delta * 13.0
		queue_redraw()
	relic_skill_cooldown_left = maxf(0.0, relic_skill_cooldown_left - delta)
	for egg in incubating_eggs:
		egg["remaining"] = maxf(0.0, float(egg.get("remaining", 0.0)) - delta)
	_companion_save_timer += delta
	if _companion_save_timer >= 10.0:
		_companion_save_timer = 0.0
		save_companions()
	_update_environment_hazards(delta)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var speed_multiplier := 1.0
	if is_instance_valid(mounted_animal):
		if mounted_animal.is_mounted:
			speed_multiplier = mounted_animal.get_mount_speed_multiplier()
		else:
			mounted_animal = null
	velocity = direction * move_speed * speed_multiplier
	move_and_slide()
	if direction.length_squared() > 0.01:
		queue_redraw()
	if is_instance_valid(mounted_animal):
		mounted_animal.global_position = global_position + Vector2(0.0, 18.0)


func _on_region_changed(region_id: String, _data: Dictionary) -> void:
	current_region_id = region_id
	if region_id == "swampland" and inventory.get_amount("herbal_antidote") > 0:
		inventory.remove_item("herbal_antidote", 1)
		antidote_seconds = 90.0
	elif region_id.is_empty():
		antidote_seconds = 0.0

func _update_environment_hazards(delta: float) -> void:
	if current_region_id.is_empty():
		return
	antidote_seconds = maxf(0.0, antidote_seconds - delta)
	hazard_damage_timer += delta
	if hazard_damage_timer < 1.0:
		return
	hazard_damage_timer = 0.0
	var damage := 0.0
	match current_region_id:
		"frostlands":
			damage = 0.65 if inventory.get_amount("fur_cloak") <= 0 else 0.12
		"cavern":
			damage = 0.55 if inventory.get_amount("torch") <= 0 else 0.12
		"swampland":
			damage = 0.5 if antidote_seconds <= 0.0 else 0.0
	if damage > 0.0:
		take_damage(damage)

func collect_resource(resource_type: String, amount: int) -> void:
	inventory.add_item(resource_type, amount)

func take_damage(amount: float) -> void:
	if is_instance_valid(survival_stats):
		survival_stats.take_damage(amount)

func attack_nearby() -> bool:
	if attack_cooldown_left > 0.0:
		return false
	var nearest: Node2D
	var nearest_distance := attack_range
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance <= nearest_distance:
			nearest = node
			nearest_distance = distance
	if nearest == null:
		return false
	var damage := 10.0
	if inventory.get_amount("relic_cavern_hammer") > 0:
		damage = 68.0
	elif inventory.get_amount("relic_mammoth_axe") > 0:
		damage = 58.0
	elif inventory.get_amount("relic_saber_blade") > 0:
		damage = 54.0
	elif inventory.get_amount("relic_thunder_spear") > 0:
		damage = 52.0
	elif inventory.get_amount("relic_swamp_claw") > 0:
		damage = 49.0
	elif inventory.get_amount("relic_frost_bow") > 0:
		damage = 46.0
	elif inventory.get_amount("stone_spear") > 0:
		damage = 28.0
	elif inventory.get_amount("stone_axe") > 0:
		damage = 22.0
	if nearest.has_method("take_damage"):
		nearest.take_damage(damage)
		attack_flash = 0.18
		queue_redraw()
		attack_cooldown_left = attack_cooldown
		return true
	return false

func use_relic_weapon_skill() -> String:
	if relic_skill_cooldown_left > 0.0:
		return "Kỹ năng di vật đang hồi chiêu: %d giây" % ceili(relic_skill_cooldown_left)
	var weapon_id := ""
	for candidate in ["relic_cavern_hammer", "relic_mammoth_axe", "relic_saber_blade", "relic_thunder_spear", "relic_swamp_claw", "relic_frost_bow"]:
		if inventory.get_amount(candidate) > 0:
			weapon_id = candidate
			break
	if weapon_id.is_empty():
		return "Cần chế tạo một vũ khí di vật từ cổ vật Boss trước"
	var enemies: Array[Node2D] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is Node2D and node.has_method("take_damage"):
			enemies.append(node as Node2D)
	if enemies.is_empty():
		return "Không có kẻ địch để dùng kỹ năng"
	var hit_count := 0
	var nearest: Node2D
	var nearest_distance := INF
	for enemy in enemies:
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	match weapon_id:
		"relic_cavern_hammer":
			for enemy in enemies:
				if global_position.distance_to(enemy.global_position) <= 190.0:
					enemy.take_damage(58.0)
					hit_count += 1
			if hit_count == 0:
				return "Đến gần kẻ địch hơn để tạo Chấn Địa"
			relic_skill_cooldown_left = RELIC_SKILL_COOLDOWN
			return "CHẤN ĐỊA HANG ĐỘNG! Gây 58 sát thương trong vùng rộng (%d mục tiêu)" % hit_count
		"relic_mammoth_axe":
			for enemy in enemies:
				if global_position.distance_to(enemy.global_position) <= 145.0:
					enemy.take_damage(48.0)
					hit_count += 1
			if hit_count == 0:
				return "Đến gần kẻ địch hơn để dùng Rìu Quét"
			relic_skill_cooldown_left = RELIC_SKILL_COOLDOWN
			return "RÌU QUÉT MA MÚT! Chém lan 48 sát thương (%d mục tiêu)" % hit_count
		"relic_saber_blade":
			if nearest_distance > 150.0:
				return "Mục tiêu phải ở trong 150 đơn vị"
			nearest.take_damage(82.0)
			relic_skill_cooldown_left = RELIC_SKILL_COOLDOWN
			return "SONG TRẢO CHÍ MẠNG! Hai nhát chém tổng 82 sát thương"
		"relic_thunder_spear":
			enemies.sort_custom(func(a: Node2D, b: Node2D) -> bool:
				return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
			)
			for index in range(mini(3, enemies.size())):
				if global_position.distance_to(enemies[index].global_position) > 420.0:
					continue
				enemies[index].take_damage(45.0)
				hit_count += 1
			if hit_count == 0:
				return "Không có mục tiêu trong tầm sét 420 đơn vị"
			relic_skill_cooldown_left = RELIC_SKILL_COOLDOWN
			return "SẤM SÉT LIÊN KÍCH! Đánh trúng %d mục tiêu" % hit_count
		"relic_swamp_claw":
			if nearest_distance > 150.0:
				return "Mục tiêu phải ở trong 150 đơn vị"
			nearest.take_damage(35.0)
			if nearest.has_method("apply_poison"):
				nearest.apply_poison(6.0, 8.0)
			relic_skill_cooldown_left = RELIC_SKILL_COOLDOWN
			return "NỌC ĐỘC ĐẦM LẦY! 35 sát thương và độc 8/giây trong 6 giây"
		"relic_frost_bow":
			if nearest_distance > 520.0:
				return "Mục tiêu phải ở trong tầm 520 đơn vị"
			nearest.take_damage(32.0)
			if nearest.has_method("apply_slow"):
				nearest.apply_slow(4.0, 0.35)
			relic_skill_cooldown_left = RELIC_SKILL_COOLDOWN
			return "BĂNG PHONG TIỄN! 32 sát thương, làm chậm 65% trong 4 giây"
	return "Không thể kích hoạt kỹ năng di vật"

func shoot_arrow() -> bool:
	if inventory.get_amount("bow") <= 0 or inventory.get_amount("arrows") <= 0:
		return false
	if attack_cooldown_left > 0.0:
		return false
	var target_enemy: Node2D
	var nearest_distance := 520.0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or not node is Node2D:
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance < nearest_distance:
			target_enemy = node
			nearest_distance = distance
	if target_enemy == null:
		return false
	if not inventory.remove_item("arrows", 1):
		return false
	var projectile := ArrowProjectile.new()
	projectile.global_position = global_position
	projectile.direction = global_position.direction_to(target_enemy.global_position)
	projectile.damage = 24.0
	get_tree().current_scene.add_child(projectile)
	attack_cooldown_left = 0.8
	return true


func tame_nearby_animal() -> String:
	var nearest: PrehistoricAnimal
	var nearest_distance := 105.0
	for node in get_tree().get_nodes_in_group("prehistoric_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal or node.is_tamed:
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance <= nearest_distance:
			nearest = node
			nearest_distance = distance
	if nearest == null:
		return "Không có thú hoang trong tầm thuần hóa"
	if get_tree().get_nodes_in_group("tamed_animals").size() + incubating_eggs.size() >= 3:
		return "Đội thú và trứng đã chiếm đủ 3 chỗ"
	var food_item := "meat"
	var food_cost := 2
	match nearest.species:
		"wolf":
			food_item = "meat"
			food_cost = 2
		"saber_tooth":
			food_item = "meat"
			food_cost = 5
		"cave_bear":
			food_item = "meat"
			food_cost = 6
		"mammoth":
			food_item = "food"
			food_cost = 8
	if inventory.get_amount(food_item) < food_cost:
		return "Cần %d %s để thuần hóa" % [food_cost, food_item]
	if not inventory.remove_item(food_item, food_cost):
		return "Không thể tiêu hao thức ăn"
	nearest.tame_as_companion()
	_register_companion(nearest)
	save_companions()
	return "Đã thuần hóa: " + nearest.enemy_name

func gather_nearby() -> bool:
	var nearest: ResourceNode
	var nearest_distance := gather_distance
	for node in get_tree().get_nodes_in_group("resource_nodes"):
		if not is_instance_valid(node) or not node is ResourceNode:
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance <= nearest_distance:
			nearest = node
			nearest_distance = distance
	if nearest == null:
		return false
	return nearest.gather_now(self)

func _draw() -> void:
	# Bóng đổ mềm, chân và bàn chân da.
	draw_colored_polygon(PackedVector2Array([Vector2(-14, 10), Vector2(-10, 21), Vector2(11, 21), Vector2(15, 10), Vector2(0, 5)]), Color(0.08, 0.10, 0.07, 0.34))
	var facing := Vector2.DOWN
	if velocity.length_squared() > 8.0:
		facing = velocity.normalized()
	var step := sin(walk_phase) * 5.0 if velocity.length_squared() > 10.0 else 0.0
	draw_line(Vector2(-5, 5), Vector2(-7.0 - step, 16), Color("#30251f"), 6.0)
	draw_line(Vector2(5, 5), Vector2(7.0 + step, 16), Color("#30251f"), 6.0)
	draw_line(Vector2(-7.0 - step, 16), Vector2(-10.0 - step, 18), Color("#c49a66"), 4.0)
	draw_line(Vector2(7.0 + step, 16), Vector2(10.0 + step, 18), Color("#c49a66"), 4.0)
	# Tấm áo da nhiều lớp và đường khâu.
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -8), Vector2(-9, 7), Vector2(0, 13), Vector2(9, 7), Vector2(11, -8), Vector2(0, -14)]), Color("#67412f"))
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -9), Vector2(-7, 6), Vector2(0, 10), Vector2(7, 6), Vector2(9, -9), Vector2(0, -12)]), Color("#a86b42"))
	draw_line(Vector2(-8, -5), Vector2(7, 8), Color("#e1c18a"), 2.5)
	draw_line(Vector2(-8, 4), Vector2(7, 4), Color("#70442f"), 1.4)
	draw_circle(Vector2(-5, 1), 1.1, Color("#e8c995"))
	draw_circle(Vector2(5, 6), 1.1, Color("#e8c995"))
	# Vai lông thú và dây đeo.
	draw_arc(Vector2(0, -8), 10.0, PI + 0.15, TAU - 0.15, 16, Color("#e1cfaa"), 3.0)
	draw_line(Vector2(-8, -6), Vector2(7, 7), Color("#4c3024"), 3.0)
	draw_circle(Vector2(7, 7), 2.0, Color("#d7b879"))
	# Đầu, tóc, tai và nét mặt.
	draw_circle(Vector2(-8.5, -13), 2.2, Color("#b9784d"))
	draw_circle(Vector2(8.5, -13), 2.2, Color("#b9784d"))
	draw_circle(Vector2(0, -14), 9.5, Color("#d9a066"))
	draw_arc(Vector2(0, -16), 9.5, PI, TAU, 18, Color("#39271e"), 5.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -18), Vector2(-5, -25), Vector2(1, -22), Vector2(7, -24), Vector2(9, -16)]), Color("#39271e"))
	draw_circle(Vector2(-3.5, -14), 1.25, Color("#292018"))
	draw_circle(Vector2(3.5, -14), 1.25, Color("#292018"))
	draw_line(Vector2(-2, -8), Vector2(2, -8), Color("#74422f"), 1.4)
	draw_circle(Vector2(0, -11), 1.0, Color("#f0bd8b"))
	# Vũ khí đá có cán, lưỡi và dây buộc.
	draw_line(Vector2(10, -1), Vector2(18, -17), Color("#503624"), 3.2)
	draw_line(Vector2(11, -3), Vector2(19, -18), Color("#bd9664"), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(15, -19), Vector2(22, -27), Vector2(23, -15), Vector2(18, -12)]), Color("#89968f"))
	draw_line(Vector2(18, -19), Vector2(21, -22), Color("#dce3d5"), 1.2)
	draw_arc(Vector2.ZERO, 21.0, 0.0, TAU, 36, Color(0.95, 0.84, 0.38, 0.85), 1.8)
	if attack_flash > 0.0:
		draw_arc(Vector2.ZERO, 34.0, -0.9, 1.0, 20, Color("#fff0a0"), 5.0)
func toggle_mount_nearby_animal() -> String:
	if is_instance_valid(mounted_animal):
		mounted_animal.is_mounted = false
		mounted_animal.mount_owner = null
		mounted_animal.z_index = 0
		var old_name := mounted_animal.enemy_name
		mounted_animal = null
		save_companions()
		return "Đã xuống thú: " + old_name
	mounted_animal = null
	var nearest: PrehistoricAnimal
	var nearest_distance := 130.0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal or node.is_mounted:
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance <= nearest_distance:
			nearest = node
			nearest_distance = distance
	if nearest == null:
		return "Cần đứng gần thú đã thuần hóa để cưỡi"
	mounted_animal = nearest
	nearest.is_mounted = true
	nearest.mount_owner = self
	nearest.z_index = -1
	nearest.global_position = global_position + Vector2(0.0, 18.0)
	save_companions()
	return "Đang cưỡi " + nearest.enemy_name + " | Tốc độ x%.2f" % nearest.get_mount_speed_multiplier()

func upgrade_nearby_companion() -> String:
	var nearest: PrehistoricAnimal
	var nearest_distance := 150.0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal or node.is_baby:
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance <= nearest_distance:
			nearest = node
			nearest_distance = distance
	if nearest == null:
		return "Hãy đến gần thú trưởng thành để nâng cấp"
	if nearest.companion_level >= 3:
		return "Thú đã đạt cấp 3; cần thức tỉnh Thần Thú riêng"
	if inventory.get_amount("bone") < 5 or inventory.get_amount("hide") < 3:
		return "Cần 5 xương và 3 da thú để nâng cấp"
	if not inventory.remove_item("bone", 5):
		return "Không đủ xương"
	if not inventory.remove_item("hide", 3):
		inventory.add_item("bone", 5)
		return "Không đủ da thú"
	nearest.upgrade_companion()
	save_companions()
	return "%s đã lên cấp %d" % [nearest.enemy_name, nearest.companion_level]



func awaken_nearby_god_beast() -> String:
	var nearest: PrehistoricAnimal
	var nearest_distance := 160.0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var animal := node as PrehistoricAnimal
		if animal.is_baby or animal.rarity != "legendary" or animal.companion_level != 3:
			continue
		var distance := global_position.distance_to(animal.global_position)
		if distance <= nearest_distance:
			nearest = animal
			nearest_distance = distance
	if nearest == null:
		return "Cần thú Huyền Thoại trưởng thành cấp 3 ở gần để thức tỉnh"
	if inventory.get_amount("bone") < 12 or inventory.get_amount("ore") < 8 or inventory.get_amount("hide") < 5:
		return "Thức tỉnh cần 12 xương, 8 quặng và 5 da thú"
	if not inventory.remove_item("bone", 12):
		return "Không đủ xương"
	if not inventory.remove_item("ore", 8):
		inventory.add_item("bone", 12)
		return "Không đủ quặng"
	if not inventory.remove_item("hide", 5):
		inventory.add_item("bone", 12)
		inventory.add_item("ore", 8)
		return "Không đủ da thú"
	if not nearest.upgrade_companion():
		inventory.add_item("bone", 12)
		inventory.add_item("ore", 8)
		inventory.add_item("hide", 5)
		return "Thức tỉnh thất bại, nguyên liệu đã hoàn lại"
	save_companions()
	return "%s đã thức tỉnh thành THẦN THÚ!" % nearest.enemy_name


func equip_nearby_companion_gear() -> String:
	var nearest: PrehistoricAnimal
	var nearest_distance := 150.0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal or node.is_baby:
			continue
		var animal := node as PrehistoricAnimal
		var distance := global_position.distance_to(animal.global_position)
		if distance <= nearest_distance:
			nearest = animal
			nearest_distance = distance
	if nearest == null:
		return "Hãy đến gần thú trưởng thành để trang bị"
	var equipped := false
	if not nearest.companion_armor_equipped and inventory.get_amount("companion_armor") > 0:
		if inventory.remove_item("companion_armor", 1):
			nearest.companion_armor_equipped = true
			equipped = true
	if not nearest.companion_fang_equipped and inventory.get_amount("companion_fang") > 0:
		if inventory.remove_item("companion_fang", 1):
			nearest.companion_fang_equipped = true
			equipped = true
	if not equipped:
		return "Cần chế tạo Giáp thú và Bùa nanh trong túi đồ, hoặc thú đã mang đủ trang bị"
	save_companions()
	return "Đã trang bị cho %s: %s%s" % [
		nearest.enemy_name,
		"Giáp thú " if nearest.companion_armor_equipped else "",
		"Bùa nanh" if nearest.companion_fang_equipped else ""
	]


func feed_nearby_companion() -> String:
	var nearest: PrehistoricAnimal
	var nearest_distance := 165.0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var animal := node as PrehistoricAnimal
		if animal.health >= animal.max_health - 0.1:
			continue
		var distance := global_position.distance_to(animal.global_position)
		if distance <= nearest_distance:
			nearest = animal
			nearest_distance = distance
	if nearest == null:
		return "Không có thú bị thương trong tầm chăm sóc"
	var food_item := "meat"
	var food_cost := 2
	if nearest.species == "mammoth":
		food_item = "food"
		food_cost = 3
	if inventory.get_amount(food_item) < food_cost:
		return "Cần %d %s để cho %s ăn" % [food_cost, food_item, nearest.enemy_name]
	if not inventory.remove_item(food_item, food_cost):
		return "Không thể tiêu hao thức ăn"
	var restored := minf(nearest.max_health * 0.4, nearest.max_health - nearest.health)
	nearest.health += restored
	save_companions()
	return "%s đã hồi %d máu" % [nearest.enemy_name, roundi(restored)]


func get_companion_herd_summary() -> String:
	var companions := get_tree().get_nodes_in_group("tamed_animals")
	if companions.is_empty():
		return "Đàn thú: chưa có thú đồng hành"
	var lines: PackedStringArray = ["ĐÀN THÚ (%d/3)" % companions.size()]
	for node in companions:
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var animal := node as PrehistoricAnimal
		var rarity_text := " | Hiếm" if animal.rarity == "rare" else (" | Huyền thoại" if animal.rarity == "legendary" else "")
		if animal.mutation != "none":
			rarity_text += " | Đột biến " + animal.get_mutation_name()
		if animal.is_pack_leader:
			rarity_text += " | THÚ CHÚA"
		var stage := "Thú con" if animal.is_baby else "%s (Cấp %d)" % [animal.get_evolution_name(), animal.companion_level]
		stage += rarity_text
		var riding := " | Đang cưỡi" if animal.is_mounted else ""
		var gear := " | Giáp" if animal.companion_armor_equipped else ""
		if animal.companion_fang_equipped:
			gear += " | Bùa nanh"
		lines.append("%s — Máu %d/%d — %s%s%s" % [
			animal.enemy_name,
			roundi(animal.health),
			roundi(animal.max_health),
			stage,
			riding,
			gear
		])
	return "\n".join(lines)


func appoint_pack_leader() -> String:
	var chosen: PrehistoricAnimal
	var chosen_distance := 180.0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var animal := node as PrehistoricAnimal
		if animal.is_baby or animal.rarity != "legendary" or animal.companion_level < 4:
			continue
		var distance := global_position.distance_to(animal.global_position)
		if distance <= chosen_distance:
			chosen = animal
			chosen_distance = distance
	if chosen == null:
		return "Cần Thần Thú Huyền Thoại cấp 4 ở gần để phong làm Thú Chúa"
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if is_instance_valid(node) and node is PrehistoricAnimal:
			(node as PrehistoricAnimal).is_pack_leader = false
	chosen.is_pack_leader = true
	chosen.queue_redraw()
	save_companions()
	return "%s được phong làm THÚ CHÚA! Đàn thú gần đó tăng 15%% sát thương và 10%% tốc độ" % chosen.enemy_name


func command_companions_attack() -> String:
	var count := 0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var animal := node as PrehistoricAnimal
		if animal.is_baby or animal.is_mounted:
			continue
		animal.set_companion_order("attack")
		count += 1
	save_companions()
	if count == 0:
		return "Chưa có thú trưởng thành sẵn sàng chiến đấu"
	return "Đã ra lệnh TẤN CÔNG cho %d thú" % count


func command_companions_protect() -> String:
	var count := 0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var animal := node as PrehistoricAnimal
		animal.set_companion_order("protect")
		count += 1
	save_companions()
	if count == 0:
		return "Bạn chưa có thú đồng hành"
	return "Đội thú chuyển sang BẢO VỆ người chơi"


func get_companion_combat_summary() -> String:
	var lines: PackedStringArray = ["KỸ NĂNG ĐÀN THÚ"]
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var animal := node as PrehistoricAnimal
		var order_text := "Tấn công" if animal.companion_order == "attack" else "Bảo vệ"
		lines.append("%s: %s | %s | Lệnh: %s" % [
			animal.enemy_name,
			animal.get_companion_skill_name(),
			animal.get_evolution_name(),
			order_text
		])
	if lines.size() == 1:
		return "Chưa có thú đồng hành"
	return "\n".join(lines)


func _register_companion(animal: PrehistoricAnimal) -> void:
	if not is_instance_valid(animal):
		return
	if not animal.tree_exited.is_connected(_on_companion_tree_exited):
		animal.tree_exited.connect(_on_companion_tree_exited)

func _on_companion_tree_exited() -> void:
	if not _loading_companions:
		call_deferred("save_companions")

func save_companions() -> void:
	if _loading_companions:
		return
	var config := ConfigFile.new()
	var index := 0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var animal := node as PrehistoricAnimal
		var section := "companion_%d" % index
		config.set_value(section, "species", animal.species)
		config.set_value(section, "rarity", animal.rarity)
		config.set_value(section, "mutation", animal.mutation)
		config.set_value(section, "level", animal.companion_level)
		config.set_value(section, "is_baby", animal.is_baby)
		config.set_value(section, "growth_remaining", animal.growth_seconds_remaining)
		config.set_value(section, "health", animal.health)
		config.set_value(section, "order", animal.companion_order)
		config.set_value(section, "armor", animal.companion_armor_equipped)
		config.set_value(section, "fang", animal.companion_fang_equipped)
		config.set_value(section, "pack_leader", animal.is_pack_leader)
		config.set_value(section, "mounted", animal.is_mounted and animal == mounted_animal)
		config.set_value(section, "offset", animal.global_position - global_position)
		index += 1
	config.set_value("companions", "count", index)
	config.set_value("eggs", "count", incubating_eggs.size())
	for egg_index in range(incubating_eggs.size()):
		var egg_section := "egg_%d" % egg_index
		config.set_value(egg_section, "species", str(incubating_eggs[egg_index].get("species", "wolf")))
		config.set_value(egg_section, "remaining", float(incubating_eggs[egg_index].get("remaining", 0.0)))
		config.set_value(egg_section, "rarity", str(incubating_eggs[egg_index].get("rarity", "common")))
		config.set_value(egg_section, "mutation", str(incubating_eggs[egg_index].get("mutation", "none")))
	config.save(COMPANION_SAVE_PATH)

func _load_companions() -> void:
	var config := ConfigFile.new()
	var error := config.load(COMPANION_SAVE_PATH)
	if error != OK:
		return
	_loading_companions = true
	incubating_eggs.clear()
	var egg_count := clampi(int(config.get_value("eggs", "count", 0)), 0, 3)
	for egg_index in range(egg_count):
		var egg_section := "egg_%d" % egg_index
		var egg_species := str(config.get_value(egg_section, "species", "wolf"))
		if egg_species in ["wolf", "saber_tooth", "cave_bear", "mammoth"]:
			incubating_eggs.append({
				"species": egg_species,
				"remaining": maxf(0.0, float(config.get_value(egg_section, "remaining", 0.0))),
				"rarity": str(config.get_value(egg_section, "rarity", "common")),
				"mutation": str(config.get_value(egg_section, "mutation", "none"))
			})
	var count := clampi(int(config.get_value("companions", "count", 0)), 0, 3)
	for index in range(count):
		var section := "companion_%d" % index
		var species := str(config.get_value(section, "species", "wolf"))
		if not ["wolf", "saber_tooth", "cave_bear", "mammoth"].has(species):
			continue
		var animal := ANIMAL_SCENE.instantiate() as PrehistoricAnimal
		animal.species = species
		var scene_root := get_tree().current_scene
		if scene_root == null:
			scene_root = get_parent()
		scene_root.add_child(animal)
		animal.global_position = global_position + config.get_value(section, "offset", Vector2(80.0 + index * 36.0, 50.0))
		animal.tame_as_companion()
		animal.set_rarity(str(config.get_value(section, "rarity", "common")))
		animal.set_mutation(str(config.get_value(section, "mutation", "none")))
		animal.set_companion_order(str(config.get_value(section, "order", "protect")))
		animal.companion_armor_equipped = bool(config.get_value(section, "armor", false))
		animal.companion_fang_equipped = bool(config.get_value(section, "fang", false))
		animal.is_pack_leader = bool(config.get_value(section, "pack_leader", false))
		if bool(config.get_value(section, "is_baby", false)):
			animal.set_as_baby(float(config.get_value(section, "growth_remaining", 300.0)))
		var level := clampi(int(config.get_value(section, "level", 1)), 1, 4)
		for _upgrade_index in range(level - 1):
			animal.upgrade_companion()
		animal.health = clampf(float(config.get_value(section, "health", animal.max_health)), 1.0, animal.max_health)
		_register_companion(animal)
		if bool(config.get_value(section, "mounted", false)) and not is_instance_valid(mounted_animal):
			mounted_animal = animal
			animal.is_mounted = true
			animal.mount_owner = self
			animal.z_index = -1
			animal.global_position = global_position + Vector2(0.0, 18.0)
	_loading_companions = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_companions()


func breed_nearby_companions() -> String:
	var companions: Array[PrehistoricAnimal] = []
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if is_instance_valid(node) and node is PrehistoricAnimal:
			var animal := node as PrehistoricAnimal
			if not animal.is_baby and not animal.is_mounted and global_position.distance_to(animal.global_position) <= 190.0:
				companions.append(animal)
	if companions.size() < 2:
		return "Cần 2 thú trưởng thành ở gần để sinh sản"
	if get_tree().get_nodes_in_group("tamed_animals").size() + incubating_eggs.size() >= 3:
		return "Đội thú và trứng đã chiếm đủ 3 chỗ"
	var parent_a: PrehistoricAnimal
	var parent_b: PrehistoricAnimal
	var best_distance := 190.0
	for i in range(companions.size()):
		for j in range(i + 1, companions.size()):
			var first := companions[i]
			var second := companions[j]
			if first.species != second.species:
				continue
			var distance := first.global_position.distance_to(second.global_position)
			if distance <= best_distance:
				best_distance = distance
				parent_a = first
				parent_b = second
	if not is_instance_valid(parent_a) or not is_instance_valid(parent_b):
		return "Cần 2 thú trưởng thành cùng loài ở gần nhau"
	if inventory.get_amount("food") < 10 or inventory.get_amount("meat") < 5:
		return "Sinh sản cần 10 lương thực và 5 thịt"
	if not inventory.remove_item("food", 10):
		return "Không đủ lương thực"
	if not inventory.remove_item("meat", 5):
		inventory.add_item("food", 10)
		return "Không đủ thịt"
	var inherited_rarity := "common"
	if parent_a.rarity == "legendary" and parent_b.rarity == "legendary":
		inherited_rarity = "legendary" if randf() < 0.2 else "rare"
	elif parent_a.rarity != "common" or parent_b.rarity != "common":
		inherited_rarity = "legendary" if randf() < 0.04 else "rare"
	var mutation_roll := randf()
	var egg_mutation := "divine" if mutation_roll < 0.01 and inherited_rarity == "legendary" else ("ember" if mutation_roll < 0.04 else ("frost" if mutation_roll < 0.07 else ("venom" if mutation_roll < 0.10 else ("storm" if mutation_roll < 0.13 else "none"))))
	incubating_eggs.append({"species": parent_a.species, "remaining": 180.0, "rarity": inherited_rarity, "mutation": egg_mutation})
	save_companions()
	var mutation_label := " | Đột biến: " + egg_mutation if egg_mutation != "none" else ""
	return "Đã đẻ trứng %s (%s%s)! Thời gian ấp: 3 phút" % [parent_a.enemy_name, inherited_rarity, mutation_label]



func hatch_ready_egg() -> String:
	if incubating_eggs.is_empty():
		return "Chưa có trứng đang ấp"
	if get_tree().get_nodes_in_group("tamed_animals").size() >= 3:
		return "Đội thú đã đủ 3 con, chưa thể nở thêm"
	var ready_index := -1
	for index in range(incubating_eggs.size()):
		if float(incubating_eggs[index].get("remaining", 0.0)) <= 0.0:
			ready_index = index
			break
	if ready_index < 0:
		var remaining := 180.0
		for egg in incubating_eggs:
			remaining = minf(remaining, float(egg.get("remaining", 180.0)))
		return "Trứng chưa nở, còn khoảng %d giây" % ceili(remaining)
	var species := str(incubating_eggs[ready_index].get("species", "wolf"))
	var ready_egg: Dictionary = incubating_eggs[ready_index].duplicate(true)
	incubating_eggs.remove_at(ready_index)
	var baby := ANIMAL_SCENE.instantiate() as PrehistoricAnimal
	baby.species = species
	var scene_root := get_tree().current_scene
	if scene_root == null:
		scene_root = get_parent()
	scene_root.add_child(baby)
	baby.global_position = global_position + Vector2(36.0, 32.0)
	baby.tame_as_companion()
	var rarity_roll := randf()
	var baby_rarity := "legendary" if rarity_roll < 0.02 else ("rare" if rarity_roll < 0.14 else "common")
	var stored_rarity := str(ready_egg.get("rarity", ""))
	if stored_rarity in ["rare", "legendary"]:
		baby_rarity = stored_rarity
	baby.set_rarity(baby_rarity)
	var egg_mutation := str(ready_egg.get("mutation", "none"))
	baby.set_mutation(egg_mutation)
	baby.set_as_baby(300.0)
	_register_companion(baby)
	save_companions()
	var rarity_label := " (Huyền thoại!)" if baby.rarity == "legendary" else (" (Hiếm)" if baby.rarity == "rare" else "")
	var mutation_label := " | Đột biến " + baby.get_mutation_name() if baby.mutation != "none" else ""
	return "Trứng đã nở! %s%s%s con đã gia nhập đàn" % [baby.enemy_name, rarity_label, mutation_label]


func get_egg_summary() -> String:
	if incubating_eggs.is_empty():
		return "Ổ trứng: chưa có trứng"
	var lines: PackedStringArray = ["Ổ TRỨNG (%d)" % incubating_eggs.size()]
	for egg in incubating_eggs:
		var species := str(egg.get("species", "wolf"))
		var remaining := float(egg.get("remaining", 0.0))
		var state := "ĐÃ SẴN SÀNG NỞ" if remaining <= 0.0 else "Còn %d giây" % ceili(remaining)
		var rarity := str(egg.get("rarity", "common"))
		var mutation := str(egg.get("mutation", "none"))
		lines.append("%s — %s — %s%s" % [species, rarity, state, " — Đột biến " + mutation if mutation != "none" else ""])
	return "\n".join(lines)
