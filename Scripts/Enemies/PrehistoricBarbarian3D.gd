extends CharacterBody3D
class_name PrehistoricBarbarian3D

enum State { PATROL, CHASE, ATTACK, RETURN }
@export var is_chief := false
@export var max_health := 100.0
@export var move_speed := 3.2
@export var detection_range := 24.0
@export var attack_range := 2.1
@export var attack_damage := 10.0
var health := 100.0
var home_position := Vector3.ZERO
var patrol_target := Vector3.ZERO
var state := State.PATROL
var attack_timer := 0.0
var patrol_timer := 0.0
var _walk_phase := 0.0
var _body: MeshInstance3D
var _health_bar: MeshInstance3D

func _ready() -> void:
	add_to_group("barbarians_3d")
	health = max_health * (1.8 if is_chief else 1.0)
	home_position = global_position
	_choose_patrol()
	_build_model()

func _mat(color: Color, roughness := 0.86) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	return m

func _part(label: String, pos: Vector3, scale_value: Vector3, color: Color) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	n.mesh = mesh
	n.position = pos
	n.scale = scale_value
	n.material_override = _mat(color)
	add_child(n)
	return n

func _build_model() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.38
	capsule.height = 1.8
	shape.shape = capsule
	shape.position.y = 0.9
	add_child(shape)
	var armor := Color("#7b4931") if not is_chief else Color("#9c352b")
	_body = _part("LeatherArmor", Vector3(0, 1.0, 0), Vector3(0.48, 0.66, 0.34), armor)
	_part("Head", Vector3(0, 1.83, 0), Vector3(0.28, 0.32, 0.27), Color("#b77c57"))
	_part("Hair", Vector3(0, 2.05, -0.03), Vector3(0.3, 0.18, 0.3), Color("#30221b"))
	_part("ShoulderLeft", Vector3(-0.39, 1.38, 0), Vector3(0.22, 0.19, 0.25), Color("#9a7650"))
	_part("ShoulderRight", Vector3(0.39, 1.38, 0), Vector3(0.22, 0.19, 0.25), Color("#9a7650"))
	_part("Shield", Vector3(-0.58, 0.95, 0.08), Vector3(0.12, 0.42, 0.34), Color("#70472d"))
	_part("SpearShaft", Vector3(0.57, 1.2, 0), Vector3(0.055, 0.85, 0.055), Color("#503624"))
	_part("SpearStone", Vector3(0.57, 2.08, 0), Vector3(0.1, 0.22, 0.07), Color("#b9c2bd"))
	if is_chief:
		_part("ChiefCrown", Vector3(0, 2.25, 0), Vector3(0.34, 0.11, 0.32), Color("#d6ad55"))
		for side in [-1.0, 1.0]:
			_part("Feather", Vector3(side * 0.13, 2.55, 0), Vector3(0.055, 0.32, 0.06), Color("#a83c32"))
	var bar_back := MeshInstance3D.new()
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(0.9, 0.09, 0.04)
	bar_back.mesh = bar_mesh
	bar_back.position = Vector3(0, 2.55, 0)
	bar_back.material_override = _mat(Color("#292522"))
	add_child(bar_back)
	_health_bar = MeshInstance3D.new()
	var fill := BoxMesh.new()
	fill.size = Vector3(0.86, 0.055, 0.05)
	_health_bar.mesh = fill
	_health_bar.position = Vector3(0, 2.55, 0.03)
	_health_bar.material_override = _mat(Color("#d94b3e"))
	add_child(_health_bar)

func _choose_patrol() -> void:
	var angle := randf() * TAU
	patrol_target = home_position + Vector3(cos(angle), 0, sin(angle)) * randf_range(4.0, 11.0)
	patrol_timer = randf_range(3.0, 7.0)

func _physics_process(delta: float) -> void:
	attack_timer = maxf(0.0, attack_timer - delta)
	patrol_timer -= delta
	var target: Node3D = null
	var closest := detection_range
	var player := get_tree().get_first_node_in_group("player_3d") as Node3D
	if is_instance_valid(player):
		var player_distance := global_position.distance_to(player.global_position)
		if player_distance < closest:
			closest = player_distance
			target = player
	for resident in get_tree().get_nodes_in_group("tribe_residents_3d"):
		if not is_instance_valid(resident) or resident.is_queued_for_deletion():
			continue
		var resident_distance := global_position.distance_to(resident.global_position)
		if resident_distance < closest:
			closest = resident_distance
			target = resident
	var destination := patrol_target
	var speed := move_speed * (1.0 if not is_chief else 1.18)
	if is_instance_valid(target):
		if closest <= attack_range:
			state = State.ATTACK
			velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
			if attack_timer <= 0.0:
				attack_timer = 1.25
				if target.has_method("take_damage"):
					target.take_damage(attack_damage * (1.6 if is_chief else 1.0))
		else:
			state = State.CHASE
			destination = target.global_position
	elif global_position.distance_to(home_position) > 34.0:
		state = State.RETURN
		destination = home_position
	elif patrol_timer <= 0.0 or global_position.distance_to(patrol_target) < 1.2:
		state = State.PATROL
		_choose_patrol()
	var direction := destination - global_position
	direction.y = 0.0
	if state != State.ATTACK and direction.length() > 0.1:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		rotation.y = lerp_angle(rotation.y, atan2(direction.x, direction.z), delta * 5.0)
		_walk_phase += delta * 8.0
	velocity.y -= 22.0 * delta
	move_and_slide()
	if is_instance_valid(_health_bar):
		_health_bar.scale.x = maxf(0.03, 0.86 * health / maxf(1.0, max_health * (1.8 if is_chief else 1.0)))

func receive_damage(amount: float) -> void:
	health = maxf(0.0, health - amount)
	if health <= 0.0:
		var player := get_tree().get_first_node_in_group("player_3d")
		if player != null and player.has_method("collect_resource"):
			player.collect_resource("hide", 1)
			player.collect_resource("bone", 1)
			player.collect_resource("barbarian_trophy", 2 if is_chief else 1)
		queue_free()
