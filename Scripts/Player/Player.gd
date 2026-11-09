extends CharacterBody2D

const ArrowProjectile = preload("res://Scripts/Player/ArrowProjectile.gd")

@export var move_speed: float = 220.0
@export var gather_distance: float = 76.0

var survival_stats: SurvivalStats
var inventory: InventorySystem
var crafting: CraftingSystem
var attack_cooldown_left: float = 0.0
var current_region_id := ""
var hazard_damage_timer := 0.0
var antidote_seconds := 0.0
var mounted_animal: PrehistoricAnimal
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

func _physics_process(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
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
	if inventory.get_amount("stone_axe") > 0:
		damage = 22.0
	elif inventory.get_amount("stone_spear") > 0:
		damage = 28.0
	if nearest.has_method("take_damage"):
		nearest.take_damage(damage)
		attack_cooldown_left = attack_cooldown
		return true
	return false

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
	if get_tree().get_nodes_in_group("tamed_animals").size() >= 3:
		return "Đội thú đồng hành đã đủ 3 con"
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
	draw_circle(Vector2.ZERO, 14.0, Color("#d9a066"))
	draw_circle(Vector2(-4.0, -3.0), 2.0, Color("#292018"))
	draw_circle(Vector2(4.0, -3.0), 2.0, Color("#292018"))
	draw_arc(Vector2(0.0, 1.0), 6.0, 0.25, PI - 0.25, 12, Color("#292018"), 1.5)


func toggle_mount_nearby_animal() -> String:
	if is_instance_valid(mounted_animal):
		mounted_animal.is_mounted = false
		mounted_animal.mount_owner = null
		mounted_animal.z_index = 0
		var old_name := mounted_animal.enemy_name
		mounted_animal = null
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
	return "Đang cưỡi " + nearest.enemy_name + " | Tốc độ x%.2f" % nearest.get_mount_speed_multiplier()

func upgrade_nearby_companion() -> String:
	var nearest: PrehistoricAnimal
	var nearest_distance := 150.0
	for node in get_tree().get_nodes_in_group("tamed_animals"):
		if not is_instance_valid(node) or not node is PrehistoricAnimal:
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance <= nearest_distance:
			nearest = node
			nearest_distance = distance
	if nearest == null:
		return "Hãy đến gần thú đồng hành để nâng cấp"
	if nearest.companion_level >= 3:
		return "Thú đã đạt cấp tối đa 3"
	if inventory.get_amount("bone") < 5 or inventory.get_amount("hide") < 3:
		return "Cần 5 xương và 3 da thú để nâng cấp"
	if not inventory.remove_item("bone", 5):
		return "Không đủ xương"
	if not inventory.remove_item("hide", 3):
		inventory.add_item("bone", 5)
		return "Không đủ da thú"
	nearest.upgrade_companion()
	return "%s đã lên cấp %d" % [nearest.enemy_name, nearest.companion_level]
