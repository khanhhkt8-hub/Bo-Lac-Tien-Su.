extends CharacterBody2D

@export var move_speed: float = 220.0
@export var gather_distance: float = 76.0

var survival_stats: SurvivalStats
var inventory: InventorySystem
var crafting: CraftingSystem
var attack_cooldown_left: float = 0.0
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

func _physics_process(delta: float) -> void:
	attack_cooldown_left = maxf(0.0, attack_cooldown_left - delta)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * move_speed
	move_and_slide()

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
