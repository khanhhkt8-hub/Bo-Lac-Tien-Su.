extends CharacterBody3D
class_name PrehistoricWildlife3D

@export_enum("wolf", "saber_tooth", "cave_bear", "mammoth", "deer") var species := "wolf"
var _wander_target := Vector3.ZERO
var _wander_timer := 0.0
var _phase := 0.0
var _body_mesh: MeshInstance3D
var health := 100.0
var is_tamed := false
var _flee_target := Vector3.ZERO

func _ready() -> void:
	add_to_group("wildlife_3d")
	_build_creature()
	_wander_target = global_position

func _build_creature() -> void:
	var dimensions := Vector3(0.65, 0.62, 1.05)
	var fur := Color("#77705e")
	match species:
		"wolf":
			dimensions = Vector3(0.58, 0.62, 1.05)
			fur = Color("#77756b")
		"saber_tooth":
			dimensions = Vector3(0.82, 0.88, 1.45)
			fur = Color("#c3a77a")
		"cave_bear":
			dimensions = Vector3(1.15, 1.15, 1.35)
			fur = Color("#513b2d")
		"mammoth":
			dimensions = Vector3(1.7, 1.75, 2.2)
			fur = Color("#80634a")
		"deer":
			dimensions = Vector3(0.52, 0.72, 1.1)
			fur = Color("#a77b4e")
	var body_material := _mat(fur)
	_body_mesh = _ellipsoid("Body", Vector3(0, dimensions.y, 0), dimensions, body_material)
	var head_size := dimensions * 0.48
	_ellipsoid("Head", Vector3(0, dimensions.y + dimensions.y * 0.55, -dimensions.z * 0.72), head_size, body_material)
	var muzzle := _mat(fur.lightened(0.16))
	_ellipsoid("Muzzle", Vector3(0, dimensions.y + dimensions.y * 0.38, -dimensions.z * 1.0), head_size * Vector3(0.7, 0.55, 0.7), muzzle)
	# Bốn chân đặt theo hai trục trước/sau để dáng thú đúng kiểu động vật bốn chân.
	for side in [-1.0, 1.0]:
		for fore_aft in [-1.0, 1.0]:
			var leg := _ellipsoid("Leg", Vector3(side * dimensions.x * 0.52, dimensions.y * 0.32, fore_aft * dimensions.z * 0.38), Vector3(dimensions.x * 0.25, dimensions.y * 0.75, dimensions.x * 0.27), body_material)
			leg.rotation.x = -0.08 if fore_aft < 0.0 else 0.08
	# Đuôi và tai tạo đường nét dễ nhận biết hơn cho từng loài.
	if species != "mammoth":
		_ellipsoid("Tail", Vector3(0.0, dimensions.y * 0.88, dimensions.z * 0.95), Vector3(dimensions.x * 0.16, dimensions.y * 0.16, dimensions.z * 0.42), body_material)
	if species in ["wolf", "saber_tooth", "deer"]:
		for side in [-1.0, 1.0]:
			_ellipsoid("Ear", Vector3(side * head_size.x * 0.72, dimensions.y + dimensions.y * 0.78, -dimensions.z * 0.69), Vector3(0.12, 0.2, 0.1), body_material)
	if species == "saber_tooth":
		for side in [-1.0, 1.0]:
			_ellipsoid("Fang", Vector3(side * head_size.x * 0.55, dimensions.y + dimensions.y * 0.12, -dimensions.z * 1.05), Vector3(0.07, 0.28, 0.07), _mat(Color("#f0dfb4")))
	if species == "mammoth":
		for side in [-1.0, 1.0]:
			_ellipsoid("Tusk", Vector3(side * dimensions.x * 0.42, dimensions.y + dimensions.y * 0.28, -dimensions.z * 0.95), Vector3(0.12, 0.58, 0.12), _mat(Color("#e5d6ad")))
	if species == "deer":
		for side in [-1.0, 1.0]:
			_ellipsoid("Antler", Vector3(side * 0.2, dimensions.y + dimensions.y * 1.05, -dimensions.z * 0.72), Vector3(0.045, 0.48, 0.045), _mat(Color("#725238")))
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = dimensions.x * 0.72
	capsule.height = dimensions.y * 2.2
	shape.shape = capsule
	shape.position.y = dimensions.y
	add_child(shape)

func _ellipsoid(label: String, pos: Vector3, dimensions: Vector3, material: Material) -> MeshInstance3D:
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
	return node

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.92
	return material

func _physics_process(delta: float) -> void:
	if is_tamed:
		var player := get_tree().get_first_node_in_group("player_3d")
		if player != null:
			var follow_offset := player.global_position + player.global_transform.basis.z * 2.4 - global_position
			if follow_offset.length() > 3.0:
				var follow_direction := follow_offset.normalized()
				velocity.x = follow_direction.x * 3.6
				velocity.z = follow_direction.z * 3.6
				rotation.y = lerp_angle(rotation.y, atan2(follow_direction.x, follow_direction.z), delta * 2.0)
			else:
				velocity.x = move_toward(velocity.x, 0.0, 7.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 7.0 * delta)
			velocity.y -= 20.0 * delta
			move_and_slide()
		return
	_wander_timer -= delta
	if _wander_timer <= 0.0:
		_wander_timer = randf_range(5.0, 13.0)
		_wander_target = global_position + Vector3(randf_range(-12.0, 12.0), 0.0, randf_range(-12.0, 12.0))
	var offset := _wander_target - global_position
	if offset.length() > 1.0:
		var direction := offset.normalized()
		velocity.x = direction.x * (1.8 if species == "mammoth" else 2.8)
		velocity.z = direction.z * (1.8 if species == "mammoth" else 2.8)
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 2.0)
		_phase += delta * 7.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)
	velocity.y -= 20.0 * delta
	move_and_slide()
	for node in get_children():
		if node is MeshInstance3D and node.name == "Leg":
			node.rotation.x = sin(_phase + (PI if node.position.x < 0.0 else 0.0)) * 0.22

func receive_damage(amount: float) -> void:
	if is_tamed:
		return
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		var player := get_tree().get_first_node_in_group("player_3d")
		if player != null and player.has_method("collect_resource"):
			player.collect_resource("meat", 2 if species != "mammoth" else 6)
			player.collect_resource("hide", 1 if species != "deer" else 2)
		queue_free()
	else:
		var player := get_tree().get_first_node_in_group("player_3d")
		if player != null:
			_flee_target = global_position + (global_position - player.global_position).normalized() * 18.0
			_wander_target = _flee_target
			_wander_timer = 5.0

func tame() -> bool:
	if is_tamed:
		return false
	is_tamed = true
	remove_from_group("wildlife_3d")
	add_to_group("tamed_mounts_3d")
	_wander_timer = 0.0
	velocity = Vector3.ZERO
	return true
