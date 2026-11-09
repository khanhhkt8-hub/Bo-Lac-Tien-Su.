extends Node2D

const WORLD_EXTENT := 2400.0
const GRID_STEP := 160.0

func _draw() -> void:
	draw_rect(Rect2(Vector2(-WORLD_EXTENT, -WORLD_EXTENT), Vector2(WORLD_EXTENT * 2.0, WORLD_EXTENT * 2.0)), Color("#456b3b"))
	for x in range(-int(WORLD_EXTENT), int(WORLD_EXTENT) + 1, int(GRID_STEP)):
		draw_line(Vector2(x, -WORLD_EXTENT), Vector2(x, WORLD_EXTENT), Color(0.72, 0.82, 0.57, 0.12), 1.0)
	for y in range(-int(WORLD_EXTENT), int(WORLD_EXTENT) + 1, int(GRID_STEP)):
		draw_line(Vector2(-WORLD_EXTENT, y), Vector2(WORLD_EXTENT, y), Color(0.72, 0.82, 0.57, 0.12), 1.0)

	# Vùng khám phá: vòng màu chỉ phạm vi nhận diện từng quần xã.
	_draw_region(Vector2(-1100, -900), 650.0, Color(0.12, 0.30, 0.12, 0.18), "RỪNG")
	_draw_region(Vector2(1100, -900), 650.0, Color(0.62, 0.58, 0.20, 0.16), "ĐỒNG CỎ")
	_draw_region(Vector2(-1100, 1000), 650.0, Color(0.12, 0.42, 0.40, 0.18), "ĐẦM LẦY")
	_draw_region(Vector2(1100, 1000), 650.0, Color(0.35, 0.35, 0.38, 0.20), "HANG ĐỘNG")
	_draw_region(Vector2(0, -1800), 650.0, Color(0.72, 0.86, 0.94, 0.20), "BĂNG TUYẾT")
	_draw_region(Vector2.ZERO, 520.0, Color(0.48, 0.65, 0.34, 0.12), "BỘ LẠC")

	# Điểm tài nguyên minh họa cho giai đoạn dựng bản đồ.
	for point in [Vector2(220, 120), Vector2(-260, 180), Vector2(360, -240), Vector2(-420, -300)]:
		draw_circle(point, 20.0, Color("#6d5137"))
		draw_circle(point + Vector2(-7, -5), 6.0, Color("#9a7952"))

func _draw_region(center: Vector2, radius: float, tint: Color, label: String) -> void:
	draw_circle(center, radius, tint)
	draw_arc(center, radius, 0.0, TAU, 72, tint.lightened(0.35), 3.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-55, -radius + 42), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f4edcf"))
