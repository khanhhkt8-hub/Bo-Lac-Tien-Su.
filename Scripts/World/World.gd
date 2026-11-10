extends Node2D

const WORLD_EXTENT := 2400.0

var _ambient_time := 0.0
var _ambient_redraw_timer := 0.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	_ambient_time += delta
	_ambient_redraw_timer += delta
	# Giới hạn nhịp vẽ để hiệu ứng môi trường mượt mà mà không tốn pin quá mức.
	if _ambient_redraw_timer >= 0.12:
		_ambient_redraw_timer = 0.0
		queue_redraw()

func _draw() -> void:
	# Nền đất nhiều lớp màu thay cho mặt phẳng xanh đơn điệu.
	draw_rect(Rect2(Vector2(-WORLD_EXTENT, -WORLD_EXTENT), Vector2(WORLD_EXTENT * 2.0, WORLD_EXTENT * 2.0)), Color("#547b42"))
	var rng := RandomNumberGenerator.new()
	rng.seed = 20261110
	for i in range(620):
		var p := Vector2(rng.randf_range(-WORLD_EXTENT, WORLD_EXTENT), rng.randf_range(-WORLD_EXTENT, WORLD_EXTENT))
		var shade := rng.randf_range(-0.055, 0.055)
		var grass_color := Color(0.39 + shade, 0.57 + shade, 0.29 + shade, 0.72)
		var grass_sway := sin(_ambient_time * 2.1 + p.x * 0.013 + p.y * 0.009) * 1.8
		draw_line(p, p + Vector2(rng.randf_range(-3.0, 3.0) + grass_sway, -rng.randf_range(4.0, 10.0)), grass_color, rng.randf_range(1.0, 2.2), true)
		if i % 5 == 0:
			draw_circle(p + Vector2(3.0, 2.0), 2.0, Color("#d4c47a"))

	# Dòng suối uốn qua thung lũng, có bờ cát và vệt sáng.
	var river := PackedVector2Array([
		Vector2(-2450, -780), Vector2(-1900, -650), Vector2(-1450, -730),
		Vector2(-980, -470), Vector2(-520, -390), Vector2(-100, -120),
		Vector2(360, 20), Vector2(820, 310), Vector2(1280, 410),
		Vector2(1740, 680), Vector2(2450, 760)
	])
	draw_polyline(river, Color("#b8a36b"), 174.0, true)
	draw_polyline(river, Color("#397f9b"), 148.0, true)
	draw_polyline(river, Color("#72b8c0"), 5.0, true)
	# Dải bọt nước và ánh phản chiếu thay đổi theo thời gian.
	for i in range(18):
		var water_phase := _ambient_time * 1.25 + float(i) * 2.4
		var water_x := -2050.0 + float(i) * 235.0
		var water_y := -690.0 + float(i) * 82.0 + sin(float(i) * 0.7) * 90.0
		var foam_pos := Vector2(water_x + sin(water_phase) * 22.0, water_y + cos(water_phase * 0.6) * 8.0)
		draw_arc(foam_pos, 5.0 + sin(water_phase) * 1.8, 0.1, 2.7, 10, Color(0.84, 0.96, 0.91, 0.42), 1.4)
	for i in range(river.size() - 1):
		var mid := river[i].lerp(river[i + 1], 0.5)
		draw_arc(mid + Vector2(0, -22), 18.0, 0.1, 2.8, 16, Color(0.78, 0.94, 0.91, 0.45), 2.0)
		# Vệt sáng trôi theo mặt nước tạo cảm giác dòng suối đang chuyển động.
		var ripple_phase := _ambient_time * 1.8 + float(i) * 1.7
		var ripple_pos := mid + Vector2(cos(ripple_phase) * 34.0, sin(ripple_phase * 0.7) * 17.0)
		draw_arc(ripple_pos, 10.0 + sin(ripple_phase) * 3.0, 0.15, 2.55, 12, Color(0.78, 0.94, 0.91, 0.38), 2.0)

	# Lối mòn đất nối khu trại với các vùng kiếm ăn.
	var trail := PackedVector2Array([Vector2(-2200, 340), Vector2(-1450, 240), Vector2(-760, 180), Vector2(-180, 80), Vector2(380, 150), Vector2(980, 80), Vector2(1680, -160), Vector2(2350, -260)])
	draw_polyline(trail, Color("#6c5738"), 58.0, true)
	draw_polyline(trail, Color("#b99a63"), 43.0, true)
	for i in range(80):
		var p := Vector2(-2100.0 + float(i) * 55.0, 340.0 - float(i) * 600.0 / 80.0 + sin(float(i) * 0.17) * 95.0)
		draw_circle(p, 2.0, Color(0.55, 0.42, 0.27, 0.55))

	# Các vùng sinh thái được phân biệt bằng thảm thực vật và màu đất.
	_draw_region(Vector2(-1100, -900), 650.0, Color(0.12, 0.30, 0.12, 0.12), "RỪNG CỔ")
	_draw_region(Vector2(1100, -900), 650.0, Color(0.72, 0.61, 0.22, 0.12), "ĐỒNG CỎ")
	_draw_region(Vector2(-1100, 1000), 650.0, Color(0.12, 0.42, 0.40, 0.14), "ĐẦM LẦY")
	_draw_region(Vector2(1100, 1000), 650.0, Color(0.35, 0.35, 0.38, 0.15), "HANG ĐỘNG")
	_draw_region(Vector2(0, -1800), 650.0, Color(0.72, 0.86, 0.94, 0.16), "MIỀN BĂNG")
	_draw_region(Vector2.ZERO, 520.0, Color(0.48, 0.65, 0.34, 0.08), "LÃNH ĐỊA BỘ LẠC")

	# Cây cổ thụ rải theo cụm, chừa khoảng trống quanh điểm xuất phát.
	for i in range(112):
		var p := Vector2(rng.randf_range(-WORLD_EXTENT + 80.0, WORLD_EXTENT - 80.0), rng.randf_range(-WORLD_EXTENT + 80.0, WORLD_EXTENT - 80.0))
		if p.length() < 430.0 or absf(p.y + 0.28 * p.x - 120.0) < 105.0:
			continue
		_draw_tree(p, rng.randf_range(0.78, 1.35), rng.randi_range(0, 2))

	# Bụi cây, đá cuội và hoa dại tạo chi tiết nền.
	for i in range(150):
		var p := Vector2(rng.randf_range(-WORLD_EXTENT, WORLD_EXTENT), rng.randf_range(-WORLD_EXTENT, WORLD_EXTENT))
		if p.length() < 330.0:
			continue
		if i % 3 == 0:
			draw_circle(p, rng.randf_range(5.0, 10.0), Color("#527b3e"))
			draw_circle(p + Vector2(5, -3), 5.0, Color("#6b9148"))
		elif i % 3 == 1:
			draw_ellipse_placeholder(p)
		else:
			draw_circle(p, 2.5, Color("#e7d58b"))

	# Bãi đá và điểm mốc quanh khu vực xuất phát.
	_draw_rock_cluster(Vector2(-300, 260), 1.0)
	_draw_rock_cluster(Vector2(330, -250), 0.9)
	_draw_campfire(Vector2(0, 115))
	_draw_tent(Vector2(-95, 40), Color("#9b7047"))
	_draw_tent(Vector2(95, 45), Color("#806044"))

func _draw_region(center: Vector2, radius: float, tint: Color, label: String) -> void:
	draw_circle(center, radius, tint)
	draw_arc(center, radius, 0.0, TAU, 72, tint.lightened(0.35), 2.0)
	draw_string(ThemeDB.fallback_font, center + Vector2(-62, -radius + 42), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("#f4edcf"))

func _draw_tree(p: Vector2, size: float, variant: int) -> void:
	# Bóng đổ và rễ nổi giúp cây có khối, không còn giống các hình tròn phẳng.
	draw_ellipse_placeholder(p + Vector2(9, 15) * size, 25.0 * size, 9.0 * size, Color(0.08, 0.13, 0.07, 0.38))
	var trunk := PackedVector2Array([
		p + Vector2(-7, 7) * size, p + Vector2(-5, -23) * size,
		p + Vector2(-3, -42) * size, p + Vector2(5, -42) * size,
		p + Vector2(7, 7) * size, p + Vector2(17, 13) * size,
		p + Vector2(3, 10) * size, p + Vector2(-2, 15) * size,
		p + Vector2(-8, 9) * size, p + Vector2(-19, 13) * size
	])
	draw_colored_polygon(trunk, Color("#69452f"))
	draw_line(p + Vector2(-2, -30) * size, p + Vector2(-3, 5) * size, Color("#a77a4c"), 2.0 * size, true)
	draw_line(p + Vector2(4, -20) * size, p + Vector2(5, 3) * size, Color("#4e3528"), 1.5 * size, true)
	draw_arc(p + Vector2(0, -13) * size, 3.5 * size, 0.0, TAU, 16, Color("#4b3024"), 1.4 * size)
	# Tán nhiều tầng, có vùng sáng và cụm lá nhỏ chuyển động theo gió.
	var sway := sin(_ambient_time * 1.15 + p.x * 0.004 + p.y * 0.006) * 3.2 * size
	var canopy := Vector2(sway, 0.0)
	var base_color := Color("#294d2d") if variant == 0 else (Color("#365d32") if variant == 1 else Color("#466b36"))
	draw_circle(p + canopy + Vector2(1, -22) * size, 34.0 * size, Color("#203f28"))
	draw_circle(p + canopy + Vector2(0, -27) * size, 29.0 * size, base_color)
	draw_circle(p + canopy + Vector2(-17, -31) * size, 19.0 * size, Color("#416d38"))
	draw_circle(p + canopy + Vector2(16, -35) * size, 21.0 * size, Color("#527d3d"))
	draw_circle(p + canopy + Vector2(-4, -46) * size, 17.0 * size, Color("#648b45"))
	draw_circle(p + canopy + Vector2(-15, -43) * size, 8.0 * size, Color("#7b9d50"))
	draw_circle(p + canopy + Vector2(7, -51) * size, 9.0 * size, Color("#89a957"))
	draw_circle(p + canopy + Vector2(20, -27) * size, 7.0 * size, Color("#73964a"))
	draw_circle(p + canopy + Vector2(-7, -47) * size, 3.0 * size, Color(0.91, 0.91, 0.60, 0.48))
	draw_circle(p + canopy + Vector2(12, -38) * size, 2.5 * size, Color(0.91, 0.91, 0.60, 0.38))

func _draw_rock_cluster(p: Vector2, size: float) -> void:
	draw_ellipse_placeholder(p + Vector2(5, 11) * size, 42.0 * size, 14.0 * size, Color(0.10, 0.13, 0.11, 0.40))
	# Ba phiến đá chồng lớp với mặt sáng, cạnh tối và vết nứt.
	draw_colored_polygon(PackedVector2Array([p + Vector2(-38, 8) * size, p + Vector2(-27, -12) * size, p + Vector2(-8, -17) * size, p + Vector2(2, 7) * size, p + Vector2(-8, 17) * size, p + Vector2(-31, 17) * size]), Color("#626d69"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-25, 5) * size, p + Vector2(-15, -29) * size, p + Vector2(7, -38) * size, p + Vector2(29, -13) * size, p + Vector2(23, 13) * size, p + Vector2(-18, 17) * size]), Color("#858f88"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-15, -27) * size, p + Vector2(7, -38) * size, p + Vector2(29, -13) * size, p + Vector2(4, -17) * size]), Color("#b5beb0"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(8, 2) * size, p + Vector2(29, -13) * size, p + Vector2(23, 13) * size, p + Vector2(-18, 17) * size]), Color("#59645f"))
	draw_line(p + Vector2(-15, -24) * size, p + Vector2(5, -31) * size, Color("#d0d4c4"), 2.2 * size, true)
	draw_line(p + Vector2(12, -10) * size, p + Vector2(7, 2) * size, Color("#46534f"), 1.5 * size, true)

func _draw_campfire(p: Vector2) -> void:
	# Quầng sáng ấm tỏa quanh bếp lửa, nhiều lớp trong suốt.
	draw_circle(p, 78.0, Color(1.0, 0.48, 0.12, 0.035))
	draw_circle(p, 52.0, Color(1.0, 0.55, 0.16, 0.055))
	draw_circle(p, 31.0, Color(1.0, 0.72, 0.28, 0.08))
	draw_ellipse_placeholder(p + Vector2(0, 12), 31, 12, Color(0.12, 0.12, 0.08, 0.45))
	draw_circle(p, 22, Color("#5a4938"))
	draw_circle(p, 15, Color("#292b29"))
	var flicker := sin(_ambient_time * 13.0) * 3.5 + sin(_ambient_time * 7.0) * 2.0
	var flame_height := 25.0 + flicker
	draw_colored_polygon(PackedVector2Array([p + Vector2(-11, 6), p + Vector2(0, -flame_height), p + Vector2(11, 6)]), Color("#e17c32"))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-6, 5), p + Vector2(1.5, -flame_height * 0.58), p + Vector2(7, 5)]), Color("#f5d06a"))
	# Tia lửa bay lên, tắt dần theo quỹ đạo riêng.
	for i in range(6):
		var spark_phase := _ambient_time * (1.7 + float(i) * 0.11) + float(i) * 2.1
		var spark_pos := p + Vector2(sin(spark_phase) * (8.0 + float(i) * 2.0), -fposmod(_ambient_time * (18.0 + float(i)), 31.0) - 8.0)
		draw_circle(spark_pos, 1.0 + 0.5 * absf(sin(spark_phase)), Color(1.0, 0.72, 0.28, 0.75))
	# Khói mỏng cuộn lên từ lửa trại.
	for i in range(3):
		var phase := _ambient_time * 0.9 + float(i) * 1.9
		var smoke_pos := p + Vector2(sin(phase) * (5.0 + float(i) * 2.0), -34.0 - float(i) * 17.0 - fposmod(_ambient_time * 12.0, 17.0))
		draw_circle(smoke_pos, 4.0 + float(i), Color(0.76, 0.78, 0.70, 0.16 - float(i) * 0.035))

func _draw_tent(p: Vector2, cloth: Color) -> void:
	draw_ellipse_placeholder(p + Vector2(5, 15), 39, 12, Color(0.12, 0.15, 0.10, 0.3))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-34, 12), p + Vector2(0, -30), p + Vector2(35, 12)]), cloth)
	draw_colored_polygon(PackedVector2Array([p + Vector2(0, -30), p + Vector2(0, 12), p + Vector2(35, 12)]), cloth.darkened(0.25))
	draw_line(p + Vector2(0, -27), p + Vector2(0, 12), Color("#e0c69a"), 2.0)

func draw_ellipse_placeholder(center: Vector2, radius_x: float = 24.0, radius_y: float = 10.0, tint: Color = Color(0.1, 0.12, 0.08, 0.35)) -> void:
	var points := PackedVector2Array()
	for i in range(20):
		var angle := TAU * float(i) / 20.0
		points.append(center + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	draw_colored_polygon(points, tint)
