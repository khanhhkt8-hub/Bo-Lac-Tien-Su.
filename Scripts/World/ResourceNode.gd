extends Area2D
class_name ResourceNode

signal gathered(resource_type: String, amount: int)

@export var resource_type: String = "wood"
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

func gather_for_tribe() -> bool:
	if amount_available <= 0:
		return false
	var amount := amount_available
	amount_available = 0
	if TribeJobSystem != null:
		TribeJobSystem.add_to_stockpile(resource_type, amount)
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
		"berries":
			tint = Color("#9c426f")
		"herbs":
			tint = Color("#5d9a4d")
		"hide":
			tint = Color("#9b7654")
		"bone":
			tint = Color("#ded2ad")
		"flint":
			tint = Color("#6d737c")
		"ore":
			tint = Color("#b17b45")
		"reeds":
			tint = Color("#8b9b48")
		"ice":
			tint = Color("#91cde0")
		"meat":
			tint = Color("#a7473c")
	draw_circle(Vector2.ZERO, 23.0, tint)
	draw_circle(Vector2(-7.0, -6.0), 6.0, tint.lightened(0.25))
