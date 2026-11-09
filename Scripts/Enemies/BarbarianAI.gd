extends EnemyAI
class_name BarbarianAI

@export var alert_radius: float = 300.0
@export var barbarian_speed_bonus: float = 1.15

func _ready() -> void:
	enemy_name = "Barbarian"
	move_speed *= barbarian_speed_bonus
	super._ready()
	add_to_group("barbarians")

func _on_target_detected(new_target: Node2D) -> void:
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
