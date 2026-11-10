extends CharacterBody3D
class_name TribeResident3D

var resident_id: int = -1
var resident_name := "Dân làng"
var resident_age := 18
var resident_role := "villager"
var is_chieftain := false
var _wander_target := Vector3.ZERO
var _wander_timer := 0.0
var _walk_phase := 0.0
var _label: Label3D
var rally_order_active := false
var rally_position := Vector3.ZERO
var combat_target: Node3D
var _attack_cooldown := 0.0
var _weapon: MeshInstance3D

func setup(data: Dictionary) -> void:
	resident_id = int(data.get("id", -1))
	resident_name = str(data.get("name", "Dân làng"))
	resident_age = int(data.get("age", 18))
	resident_role = str(data.get("job", data.get("role", "villager")))
	is_chieftain = resident_role == "chieftain"
	name = "Resident_%s" % resident_id
	_build_model()
	_update_label()

func _ready() -> void:
	add_to_group("tribe_residents_3d")
	_wander_target = global_position

func _build_model() -> void:
	var body_shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.65
	body_shape.shape = capsule
	body_shape.position.y = 0.83
	add_child(body_shape)
	var skin := _mat(Color("#bd8962") if resident_id % 2 == 0 else Color("#d09a70"))
	var cloth_colors := [Color("#806044"), Color("#586d4a"), Color("#8a5140"), Color("#766b55"), Color("#665b78")]
	var cloth := _mat(Color("#9b794e") if is_chieftain else cloth_colors[resident_id % cloth_colors.size()])
	_add_capsule("Torso", Vector3(0, 1.0, 0), Vector3(0.42, 0.65, 0.31), cloth)
	_add_sphere("Head", Vector3(0, 1.78, 0), Vector3(0.26, 0.31, 0.25), skin)
	_add_sphere("Hair", Vector3(0, 1.98, -0.025), Vector3(0.28, 0.17, 0.27), _mat(Color("#30231d") if resident_id % 3 else Color("#493326")))
	for side in [-1.0, 1.0]:
		_add_capsule("Arm", Vector3(side * 0.32, 1.02, 0), Vector3(0.13, 0.43, 0.14), skin)
		_add_capsule("Leg", Vector3(side * 0.14, 0.38, 0), Vector3(0.15, 0.42, 0.16), _mat(Color("#4a3327")))
	_add_box("WaistBelt", Vector3(0, 0.72, 0), Vector3(0.48, 0.08, 0.34), _mat(Color("#4b3020")))
	_weapon = MeshInstance3D.new()
	_weapon.name = "StoneSpear"
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.035
	shaft.bottom_radius = 0.045
	shaft.height = 1.35
	_weapon.mesh = shaft
	_weapon.position = Vector3(0.48, 1.0, 0.02)
	_weapon.rotation.z = -0.18
	_weapon.material_override = _mat(Color("#67442d"))
	add_child(_weapon)
	if is_chieftain:
		_add_box("ChiefHeadband", Vector3(0, 2.03, 0), Vector3(0.48, 0.08, 0.3), _mat(Color("#d5ad58")))
		for i in range(3):
			_add_box("Feather", Vector3((i - 1) * 0.13, 2.24 + (1.0 - absf(i - 1)) * 0.07, 0), Vector3(0.07, 0.38, 0.045), _mat([Color("#a43d31"), Color("#d7b45b"), Color("#47734b")][i]))
	_label = Label3D.new()
	_label.position.y = 2.45
	_label.font_size = 28
	_label.pixel_size = 0.004
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

func _add_sphere(label: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	node.mesh = mesh
	node.position = pos
	node.scale = dimensions
	node.material_override = material
	add_child(node)

func _add_capsule(label: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.5
	mesh.height = 2.0
	node.mesh = mesh
	node.position = pos
	node.scale = dimensions
	node.material_override = material
	add_child(node)

func _add_box(label: String, pos: Vector3, dimensions: Vector3, material: Material) -> void:
	var node := MeshInstance3D.new()
	node.name = label
	var mesh := BoxMesh.new()
	mesh.size = dimensions
	node.mesh = mesh
	node.position = pos
	node.material_override = material
	add_child(node)

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.86
	return material

func _update_label() -> void:
	if not is_instance_valid(_label):
		return
	var role_text := "TỘC TRƯỞNG" if is_chieftain else resident_role.to_upper()
	_label.text = "%s\n%s · %d" % [resident_name, role_text, resident_age]
	_label.modulate = Color("#ffe2a0") if is_chieftain else Color.WHITE

func issue_rally_order(point: Vector3) -> void:
	rally_position = point
	rally_order_active = true
	combat_target = null

func _process(delta: float) -> void:
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	if resident_age >= 18:
		_update_combat(delta)
	if is_instance_valid(combat_target):
		return
	if rally_order_active and global_position.distance_to(rally_position) > 2.0:
		var rally_direction := rally_position - global_position
		rally_direction.y = 0.0
		if rally_direction.length() > 0.1:
			rally_direction = rally_direction.normalized()
			global_position += rally_direction * 2.8 * delta
			rotation.y = lerp_angle(rotation.y, atan2(rally_direction.x, rally_direction.z), 0.15)
			_walk_phase += delta * 8.0
			_update_walk_pose()
			return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(4.0, 10.0)
		if rally_order_active:
			_wander_target = rally_position + Vector3(randf_range(-5.0, 5.0), 0.0, randf_range(-5.0, 5.0))
		else:
			_wander_target = Vector3(randf_range(-28.0, 28.0), 0.0, randf_range(-28.0, 28.0))
	var offset := _wander_target - global_position
	if offset.length() > 1.2:
		var direction := offset.normalized()
		global_position += direction * 1.1 * delta
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 0.12)
		_walk_phase += delta * 7.0
		_update_walk_pose()
	else:
		_update_walk_pose(0.0)

func _update_combat(delta: float) -> void:
	var nearest: Node3D = null
	var nearest_distance := 19.0
	for enemy in get_tree().get_nodes_in_group("barbarians_3d"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
	if nearest == null:
		combat_target = null
		return
	combat_target = nearest
	var offset := nearest.global_position - global_position
	offset.y = 0.0
	if nearest_distance > 1.8:
		var direction := offset.normalized()
		global_position += direction * 3.1 * delta
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), 0.2)
		_walk_phase += delta * 9.0
		_update_walk_pose()
	elif _attack_cooldown <= 0.0:
		_attack_cooldown = 1.45
		if nearest.has_method("receive_damage"):
			nearest.receive_damage(9.0 + float(resident_age - 18) * 0.08)
		_weapon.rotation.z = -0.8
	else:
		_weapon.rotation.z = move_toward(_weapon.rotation.z, -0.18, delta * 2.5)

func _update_walk_pose(amount: float = 1.0) -> void:
	for node in get_children():
		if node is MeshInstance3D and (node.name == "Leg" or node.name == "Arm"):
			var side := -1.0 if node.position.x < 0.0 else 1.0
			node.rotation.x = sin(_walk_phase + (PI if side < 0.0 else 0.0)) * 0.24 * amount
