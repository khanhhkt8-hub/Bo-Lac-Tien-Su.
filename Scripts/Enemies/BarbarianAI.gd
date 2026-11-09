extends EnemyAI
class_name BarbarianAI

@export var alert_radius: float = 300.0
@export var barbarian_speed_bonus: float = 1.15
@export var is_chief: bool = false

func _ready() -> void:
	enemy_name = "Barbarian"
	move_speed *= barbarian_speed_bonus
	if is_chief:
		enemy_name = "Tribal Chief"
		max_health = 220.0
		attack_damage = 18.0
		move_speed *= 0.9
		alert_radius = 480.0
	super._ready()
	add_to_group("barbarians")

func take_damage(amount: float) -> void:\n\tvar was_alive := health > 0.0\n\tsuper.take_damage(amount)\n\tif is_chief and was_alive and health <= 0.0:\n\t\tTribeJobSystem.add_to_stockpile("tools", 8)\n\t\tTribeJobSystem.add_to_stockpile("food", 12)\n\t\tprint("Đã đánh bại Thủ lĩnh man rợ! Nhận 8 dụng cụ và 12 lương thực.")\n\nfunc _on_target_detected(new_target: Node2D) -> void:
	for ally in get_tree().get_nodes_in_group("barbarians"):
		if ally == self or not is_instance_valid(ally):
			continue
		if global_position.distance_to(ally.global_position) <= alert_radius:
			if ally.has_method("receive_alert"):
				ally.receive_alert(new_target)

func receive_alert(new_target: Node2D) -> void:
	if is_instance_valid(new_target):
		target = new_target
		state = AIState.CHASE

func _draw() -> void:
	super._draw()
	if is_chief:
		draw_arc(Vector2.ZERO, 19.0, 0.0, TAU, 24, Color("#e5bd48"), 3.0)
		draw_circle(Vector2(0.0, -18.0), 4.0, Color("#e5bd48"))
