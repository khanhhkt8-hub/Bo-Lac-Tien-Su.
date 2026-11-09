extends Node2D
class_name ArrowProjectile

@export var speed: float = 520.0
@export var damage: float = 24.0
@export var max_distance: float = 520.0

var direction: Vector2 = Vector2.RIGHT
var travelled: float = 0.0

func _physics_process(delta: float) -> void:
	var step := speed * delta
	global_position += direction.normalized() * step
	travelled += step
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		if global_position.distance_to(enemy.global_position) <= 22.0:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
			queue_free()
			return
	if travelled >= max_distance:
		queue_free()
	queue_redraw()

func _draw() -> void:
	draw_line(Vector2(-8.0, 0.0), Vector2(8.0, 0.0), Color("#d7bd82"), 3.0)
	draw_line(Vector2(8.0, 0.0), Vector2(4.0, -4.0), Color("#eee2c8"), 1.5)
	draw_line(Vector2(8.0, 0.0), Vector2(4.0, 4.0), Color("#eee2c8"), 1.5)
