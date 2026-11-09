extends Node2D

const WORLD_EXTENT := 2400.0
const GRID_STEP := 160.0

func _draw() -> void:
	draw_rect(Rect2(Vector2(-WORLD_EXTENT, -WORLD_EXTENT), Vector2(WORLD_EXTENT * 2.0, WORLD_EXTENT * 2.0)), Color("#456b3b"))
	for x in range(-int(WORLD_EXTENT), int(WORLD_EXTENT) + 1, int(GRID_STEP)):
		draw_line(Vector2(x, -WORLD_EXTENT), Vector2(x, WORLD_EXTENT), Color(0.72, 0.82, 0.57, 0.12), 1.0)
	for y in range(-int(WORLD_EXTENT), int(WORLD_EXTENT) + 1, int(GRID_STEP)):
		draw_line(Vector2(-WORLD_EXTENT, y), Vector2(WORLD_EXTENT, y), Color(0.72, 0.82, 0.57, 0.12), 1.0)

	# Điểm tài nguyên minh họa cho giai đoạn dựng bản đồ.
	for point in [Vector2(220, 120), Vector2(-260, 180), Vector2(360, -240), Vector2(-420, -300)]:
		draw_circle(point, 20.0, Color("#6d5137"))
		draw_circle(point + Vector2(-7, -5), 6.0, Color("#9a7952"))
