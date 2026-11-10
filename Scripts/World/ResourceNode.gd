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
	# Bệ bóng và biểu tượng tài nguyên riêng, không còn là các chấm tròn giống nhau.
	draw_ellipse_placeholder(Vector2(4, 13), 27.0, 10.0, Color(0.10, 0.14, 0.09, 0.35))
	var tint := Color("#8a633c")
	var symbol := "?"
	match resource_type:
		"wood":
			tint = Color("#47743d")
			symbol = "♣"
		"stone":
			tint = Color("#92999b")
			symbol = "◆"
		"food", "meat":
			tint = Color("#b4a34b")
			symbol = "●" if resource_type == "food" else "M"
		"water", "fish":
			tint = Color("#438eb8")
			symbol = "≈" if resource_type == "water" else "><>"
		"fruit", "berries":
			tint = Color("#d66b3d")
			symbol = "●"
		"chicken", "duck":
			tint = Color("#e4c56b")
			symbol = "♟"
		"eggs":
			tint = Color("#eee0b4")
			symbol = "o"
		"clay":
			tint = Color("#a66b51")
			symbol = "■"
		"herbs", "reeds":
			tint = Color("#5d9a4d")
			symbol = "♠"
		"hide":
			tint = Color("#9b7654")
			symbol = "H"
		"bone":
			tint = Color("#ded2ad")
			symbol = "Y"
		"flint", "ore", "ice":
			tint = Color("#6d8790") if resource_type == "ice" else Color("#858d91")
			symbol = "◆"
	draw_circle(Vector2.ZERO, 23.0, Color("#283b29"))
	draw_circle(Vector2.ZERO, 19.0, tint)
	draw_circle(Vector2(-6.0, -7.0), 6.0, tint.lightened(0.28))
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(-12.0, 6.0), symbol, HORIZONTAL_ALIGNMENT_CENTER, 25.0, 18, Color("#fff4d8"))
	draw_rect(Rect2(Vector2(-18.0, 25.0), Vector2(36.0, 5.0)), Color("#292b25"))
	draw_rect(Rect2(Vector2(-18.0, 25.0), Vector2(36.0 * float(amount_available) / 24.0, 5.0)), Color("#e5d18b"))

func draw_ellipse_placeholder(center: Vector2, radius_x: float, radius_y: float, tint: Color) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, tint)
