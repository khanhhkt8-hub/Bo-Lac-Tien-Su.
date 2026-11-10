extends CharacterBody3D
class_name PrehistoricPlayer3D

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
var _gather_cooldown := 0.0
var _nearby_resource: Node3D = null

func _ready() -> void:
	add_to_group("player_3d")
	_build_character()
	_build_camera()
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
	_add_sphere("Head", Vector3(0.0, 1.88, 0.0), Vector3(0.31, 0.36, 0.3), Color("#d5a071"))
	_add_sphere("Hair", Vector3(0.0, 2.12, -0.035), Vector3(0.33, 0.2, 0.33), Color("#30251f"))
	_add_capsule("LeftArm", Vector3(-0.34, 1.12, 0.0), Vector3(0.16, 0.48, 0.16), Color("#c18a5b"))
	_add_capsule("RightArm", Vector3(0.34, 1.12, 0.0), Vector3(0.16, 0.48, 0.16), Color("#c18a5b"))
	_add_capsule("LeftLeg", Vector3(-0.16, 0.38, 0.0), Vector3(0.17, 0.48, 0.18), Color("#4a3327"))
	_add_capsule("RightLeg", Vector3(0.16, 0.38, 0.0), Vector3(0.17, 0.48, 0.18), Color("#4a3327"))
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
	inventory[resource_type] = int(inventory.get(resource_type, 0)) + amount
	var hud := get_tree().get_first_node_in_group("hud_3d")
	if hud != null and hud.has_method("show_inventory"):
		hud.show_inventory(inventory)

func _physics_process(_delta: float) -> void:
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

func attack_nearest_wildlife() -> void:
	var target: Node3D = null
	var nearest_distance := 3.8
	for animal in get_tree().get_nodes_in_group("wildlife_3d"):
		if not is_instance_valid(animal):
			continue
		var distance := global_position.distance_to(animal.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			target = animal
	if target != null and target.has_method("receive_damage"):
		target.receive_damage(25.0)

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
	if target != null and target.tame():
		collect_resource("trust", 1)
