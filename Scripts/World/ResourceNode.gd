extends Area2D
class_name ResourceNode

signal gathered(resource_type: String, amount: int)

@export_enum("wood", "stone", "food", "water") var resource_type: String = "wood"
@export_range(1, 99, 1) var amount_available: int = 5

func _ready() -> void:
	add_to_group("resource_nodes")
	queue_redraw()

func gather_now(player: Node) -> bool:
	if amount_available <= 0 or player == null or not player.has_method("collect_resource"):
		return false
	var amount := amount_available
	amount_available = 0
	player.collect_resource(resource_type, amount)
	gathered.emit(resource_type, amount)
	queue_free()
	return true

func _draw() -> void:
	var tint := Color("#8a633c")
	match resource_type:
		"stone":
			tint = Color("#92999b")
		"food":
			tint = Color("#b4a34b")
		"water":
			tint = Color("#438eb8")
	draw_circle(Vector2.ZERO, 23.0, tint)
	draw_circle(Vector2(-7.0, -6.0), 6.0, tint.lightened(0.25))
