extends Node2D
## Persistent fog of war: unknown cells are hidden until a tribe member scouts them.

const SAVE_PATH := "user://bo_lac_fog_of_war.cfg"
const WORLD_EXTENT := 2400.0
const CELL_SIZE := 96.0
const REFRESH_INTERVAL := 0.4
const SAVE_INTERVAL := 5.0

var explored_cells: Dictionary = {}
var visible_cells: Dictionary = {}
var _refresh_timer := 0.0
var _save_timer := 0.0
var _dirty := false

func _ready() -> void:
	_load_exploration()
	_refresh_visibility()
	queue_redraw()

func _process(delta: float) -> void:
	_refresh_timer += delta
	_save_timer += delta
	if _refresh_timer >= REFRESH_INTERVAL:
		_refresh_timer = 0.0
		_refresh_visibility()
		queue_redraw()
	if _dirty and _save_timer >= SAVE_INTERVAL:
		_save_timer = 0.0
		_save_exploration()

func _refresh_visibility() -> void:
	visible_cells.clear()
	var sources: Array[Node2D] = []
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(player):
		sources.append(player)
	for unit in get_tree().get_nodes_in_group("tribe_units"):
		if is_instance_valid(unit) and unit is Node2D:
			sources.append(unit as Node2D)
	for source in sources:
		var radius := _vision_radius(source)
		var min_x := floori((source.global_position.x - radius) / CELL_SIZE)
		var max_x := floori((source.global_position.x + radius) / CELL_SIZE)
		var min_y := floori((source.global_position.y - radius) / CELL_SIZE)
		var max_y := floori((source.global_position.y + radius) / CELL_SIZE)
		for cell_x in range(min_x, max_x + 1):
			for cell_y in range(min_y, max_y + 1):
				var center := Vector2((float(cell_x) + 0.5) * CELL_SIZE, (float(cell_y) + 0.5) * CELL_SIZE)
				if center.distance_to(source.global_position) > radius + CELL_SIZE * 0.45:
					continue
				var key := _cell_key(cell_x, cell_y)
				visible_cells[key] = true
				if not explored_cells.has(key):
					explored_cells[key] = true
					_dirty = true

func _vision_radius(source: Node2D) -> float:
	if source.is_in_group("player"):
		return 440.0
	var role := str(source.get("role"))
	if role == "scout":
		return 520.0
	if role == "hunter":
		return 330.0
	if role == "warrior":
		return 290.0
	return 240.0

func _cell_key(cell_x: int, cell_y: int) -> String:
	return str(cell_x) + ":" + str(cell_y)

func _draw() -> void:
	var min_cell := floori(-WORLD_EXTENT / CELL_SIZE)
	var max_cell := ceili(WORLD_EXTENT / CELL_SIZE)
	for cell_x in range(min_cell, max_cell):
		for cell_y in range(min_cell, max_cell):
			var key := _cell_key(cell_x, cell_y)
			if visible_cells.has(key):
				continue
			var tint := Color(0.025, 0.035, 0.045, 0.97)
			if explored_cells.has(key):
				tint = Color(0.055, 0.065, 0.075, 0.48)
			draw_rect(Rect2(Vector2(cell_x, cell_y) * CELL_SIZE, Vector2.ONE * CELL_SIZE), tint)

func _load_exploration() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved: PackedStringArray = config.get_value("fog", "explored_cells", PackedStringArray())
	for key in saved:
		explored_cells[str(key)] = true

func _save_exploration() -> void:
	var config := ConfigFile.new()
	var saved := PackedStringArray()
	for key in explored_cells.keys():
		saved.append(str(key))
	config.set_value("fog", "explored_cells", saved)
	if config.save(SAVE_PATH) == OK:
		_dirty = false

func _exit_tree() -> void:
	if _dirty:
		_save_exploration()
