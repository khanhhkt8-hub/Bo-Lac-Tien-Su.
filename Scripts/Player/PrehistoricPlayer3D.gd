extends CharacterBody3D
class_name PrehistoricPlayer3D

const SAVE_PATH := "user://bo_lac_player_3d.cfg"

@export var move_speed: float = 6.5
@export var mouse_sensitivity: float = 0.004
@export var camera_distance: float = 8.5
var _camera_yaw := 0.0
var _camera_pitch := -0.28
var _camera_pivot: Node3D
var _camera: Camera3D
var _dragging := false
var _last_touch := Vector2.ZERO
var inventory: Dictionary = {}
var health := 100.0
var max_health := 100.0
var _respawn_position := Vector3.ZERO
var _gather_cooldown := 0.0
var _nearby_resource: Node3D = null
var _save_timer := 0.0
var _walk_phase := 0.0
var _body_mesh: MeshInstance3D
var _left_arm: MeshInstance3D
var _right_arm: MeshInstance3D
var _left_leg: MeshInstance3D
var _right_leg: MeshInstance3D

func _ready() -> void:
	add_to_group("player_3d")
	_build_character()
	_build_camera()
	_respawn_position = global_position
	_load_player_state()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_character() -> void:
	var body_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.85
	body_shape.shape = capsule
	body_shape.position.y = 0.95
	add_child(body_shape)
	_add_capsule("Body", Vector3(0.0, 1.05, 0.0), Vector3(0.48, 0.78, 0.34), Color("#9a633e"))
	_body_mesh = get_node_or_null("Body") as MeshInstance3D
	_add_sphere("Head", Vector3(0.0, 1.88, 0.0), Vector3(0.31, 0.36, 0.3), Color("#d5a071"))
	_add_sphere("Hair", Vector3(0.0, 2.12, -0.035), Vector3(0.33, 0.2, 0.33), Color("#30251f"))
	_add_capsule("LeftArm", Vector3(-0.34, 1.12, 0.0), Vector3(0.16, 0.48, 0.16), Color("#c18a5b"))
	_left_arm = get_node_or_null("LeftArm") as MeshInstance3D
	_add_capsule("RightArm", Vector3(0.34, 1.12, 0.0), Vector3(0.16, 0.48, 0.16), Color("#c18a5b"))
	_right_arm = get_node_or_null("RightArm") as MeshInstance3D
	_add_capsule("LeftLeg", Vector3(-0.16, 0.38, 0.0), Vector3(0.17, 0.48, 0.18), Color("#4a3327"))
	_left_leg = get_node_or_null("LeftLeg") as MeshInstance3D
	_add_capsule("RightLeg", Vector3(0.16, 0.38, 0.0), Vector3(0.17, 0.48, 0.18), Color("#4a3327"))
	_right_leg = get_node_or_null("RightLeg") as MeshInstance3D
	_add_box("LeatherStrap", Vector3(0.0, 1.14, 0.19), Vector3(0.08, 0.86, 0.035), Color("#e0bd83"))

func _add_sphere(label: String, pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	node.mesh = mesh
	node.position = pos
	node.scale = dimensions
	node.material_override = _material(color)
	add_child(node)

func _add_capsule(label: String, pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.5
	mesh.height = 2.0
	node.mesh = mesh
	node.position = pos
	node.scale = dimensions
	node.material_override = _material(color)
	add_child(node)

func _add_box(label: String, pos: Vector3, dimensions: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.position = pos
	node.material_override = _material(color)
	add_child(node)

func _material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	return material

func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.position = Vector3(0.0, 1.5, 0.0)
	add_child(_camera_pivot)
	_camera = Camera3D.new()
	_camera.position = Vector3(0.0, 2.4, camera_distance)
	_camera.fov = 62.0
	_camera.current = true
	_camera_pivot.add_child(_camera)
	_update_camera_rotation()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_camera_yaw -= event.relative.x * mouse_sensitivity
		_camera_pitch = clampf(_camera_pitch - event.relative.y * mouse_sensitivity, -0.85, 0.25)
		_update_camera_rotation()
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if event.pressed else Input.MOUSE_MODE_VISIBLE
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera_distance = maxf(4.0, camera_distance - 0.6)
			_camera.position.z = camera_distance
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera_distance = minf(14.0, camera_distance + 0.6)
			_camera.position.z = camera_distance
	elif event is InputEventScreenTouch:
		_dragging = event.pressed
		_last_touch = event.position
	elif event is InputEventScreenDrag and _dragging:
		var delta := event.position - _last_touch
		_last_touch = event.position
		_camera_yaw -= delta.x * mouse_sensitivity * 1.5
		_camera_pitch = clampf(_camera_pitch - delta.y * mouse_sensitivity * 1.5, -0.85, 0.25)
		_update_camera_rotation()

func collect_resource(resource_type: String, amount: int) -> void:
	if amount <= 0:
		return
	inventory[resource_type] = int(inventory.get(resource_type, 0)) + amount
	var hud := get_tree().get_first_node_in_group("hud_3d")
	if hud != null and hud.has_method("show_inventory"):
		hud.show_inventory(inventory)
	_save_player_state()

func _load_player_state() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var saved_inventory: Variant = config.get_value("player", "inventory", {})
	if saved_inventory is Dictionary:
		inventory = saved_inventory
	health = clampf(float(config.get_value("player", "health", max_health)), 1.0, max_health)
	var saved_position: Variant = config.get_value("player", "position", _respawn_position)
	if saved_position is Vector3:
		global_position = Vector3(clampf(saved_position.x, -850.0, 850.0), maxf(0.2, saved_position.y), clampf(saved_position.z, -850.0, 850.0))

func _save_player_state() -> void:
	var config := ConfigFile.new()
	config.set_value("player", "inventory", inventory)
	config.set_value("player", "health", health)
	config.set_value("player", "position", global_position)
	config.save(SAVE_PATH)

func _exit_tree() -> void:
	_save_player_state()

func _physics_process(_delta: float) -> void:
	_save_timer += _delta
	if _save_timer >= 8.0:
		_save_timer = 0.0
		_save_player_state()
	_gather_cooldown = maxf(0.0, _gather_cooldown - _delta)
	if Input.is_action_just_pressed("interact") and _gather_cooldown <= 0.0:
		gather_nearest_resource()
	var input_vector := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction := Vector3(input_vector.x, 0.0, input_vector.y)
	if direction.length_squared() > 0.01:
		direction = (Basis(Vector3.UP, _camera_yaw) * direction).normalized()
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 0.18)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * _delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * _delta)
	velocity.y -= 22.0 * _delta
	move_and_slide()
	_animate_character(_delta)

func _animate_character(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var moving := horizontal_speed > 0.25
	if moving:
		_walk_phase += delta * clampf(horizontal_speed * 1.7, 5.0, 12.0)
	var swing := sin(_walk_phase) * (0.48 if moving else 0.025)
	if is_instance_valid(_left_arm):
		_left_arm.rotation.x = swing
	if is_instance_valid(_right_arm):
		_right_arm.rotation.x = -swing
	if is_instance_valid(_left_leg):
		_left_leg.rotation.x = -swing * 0.82
	if is_instance_valid(_right_leg):
		_right_leg.rotation.x = swing * 0.82
	if is_instance_valid(_body_mesh):
		_body_mesh.position.y = 1.05 + (sin(_walk_phase * 2.0) * 0.035 if moving else sin(Time.get_ticks_msec() * 0.0018) * 0.012)

func _update_camera_rotation() -> void:
	if is_instance_valid(_camera_pivot):
		_camera_pivot.rotation.y = _camera_yaw
		_camera_pivot.rotation.x = _camera_pitch

func gather_nearest_resource() -> void:
	var nearest: Node3D = null
	var nearest_distance := 3.4
	for node in get_tree().get_nodes_in_group("resources_3d"):
		if not is_instance_valid(node):
			continue
		var distance := global_position.distance_to(node.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = node
	if nearest != null and nearest.has_method("gather"):
		if nearest.gather(self):
			_gather_cooldown = 0.35

func tame_nearest_wildlife() -> void:
	var target: Node3D = null
	var nearest_distance := 3.5
	for animal in get_tree().get_nodes_in_group("wildlife_3d"):
		if not is_instance_valid(animal) or not animal.has_method("tame"):
			continue
		var distance := global_position.distance_to(animal.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			target = animal
	if target == null:
		return
	var species := str(target.get("species"))
	var cost := {"wolf": ["meat", 2], "saber_tooth": ["meat", 5], "cave_bear": ["meat", 6], "mammoth": ["food", 8], "deer": ["food", 2]}.get(species, ["food", 2])
	var resource_id := str(cost[0])
	var required := int(cost[1])
	if int(inventory.get(resource_id, 0)) < required:
		var hud := get_tree().get_first_node_in_group("hud_3d")
		if hud != null and hud.has_method("show_message"):
			hud.show_message("CẦN %d %s ĐỂ THUẦN HÓA" % [required, resource_id.to_upper()])
		return
	if target.tame():
		inventory[resource_id] = int(inventory.get(resource_id, 0)) - required
		collect_resource("trust", 1)

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - maxf(0.0, amount))
	var hud := get_tree().get_first_node_in_group("hud_3d")
	if hud != null and hud.has_method("show_health"):
		hud.show_health(health, max_health)
	if health <= 0.0:
		health = max_health
		global_position = _respawn_position + Vector3(0.0, 0.5, 0.0)
		velocity = Vector3.ZERO
		collect_resource("injury_recovery", 1)
	_save_player_state()

func attack_nearest_wildlife() -> void:
	var nearest: Node3D = null
	var nearest_distance := 3.8
	for group_name in ["wildlife_3d", "barbarians_3d"]:
		for target in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(target) or not target.has_method("receive_damage"):
				continue
			var distance := global_position.distance_to(target.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest = target
	if nearest != null:
		nearest.receive_damage(28.0)
