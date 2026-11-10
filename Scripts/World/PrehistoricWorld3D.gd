extends Node3D
class_name PrehistoricWorld3D

@export var world_size: float = 1800.0
@export var tree_count: int = 180
@export var rock_count: int = 95
var _rng := RandomNumberGenerator.new()
var _tribe_sync_timer := 0.0
var _resident_nodes: Dictionary = {}

func _ready() -> void:
	_rng.seed = 20261110
	_build_environment()
	_build_terrain()
	_build_river()
	_build_forest()
	_build_rocks()
	_build_camp()
	_build_resources()
	_build_wildlife()
	_build_barbarian_camps()
	_sync_tribe_residents()

func _mat(color: Color, roughness: float = 0.9, metallic: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color("#244b70")
	sky_material.sky_horizon_color = Color("#e8b77e")
	sky_material.ground_bottom_color = Color("#182b27")
	sky_material.ground_horizon_color = Color("#8c9a83")
	sky_material.sun_angle_max = 18.0
	sky.sky_material = sky_material
	environment.sky = sky
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	environment.ambient_light_sky_contribution = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_exposure = 1.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.35
	environment.glow_strength = 0.65
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.12
	var world_environment := WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48.0, -32.0, 0.0)
	sun.light_color = Color("#fff0d5")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 100.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	add_child(sun)

func _build_terrain() -> void:
	var ground := MeshInstance3D.new()
	ground.name = "AncientGrassland"
	var plane := PlaneMesh.new()
	plane.size = Vector2(world_size, world_size)
	plane.subdivide_width = 100
	plane.subdivide_depth = 100
	ground.mesh = plane
	ground.position.y = -0.25
	ground.material_override = _mat(Color("#65884a"))
	add_child(ground)
	var body := StaticBody3D.new()
	body.name = "TerrainCollision"
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(world_size, 1.0, world_size)
	collision.shape = shape
	collision.position.y = -0.5
	body.add_child(collision)
	add_child(body)
	# Mảng cỏ thấp tạo chiều sâu bề mặt nhưng giới hạn số draw call.
	var grass_mesh := BoxMesh.new()
	grass_mesh.size = Vector3(0.09, 0.48, 0.035)
	var grass_material := _mat(Color("#91a95a"))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = grass_mesh
	multimesh.instance_count = 2200
	for i in range(multimesh.instance_count):
		var x := _rng.randf_range(-world_size * 0.48, world_size * 0.48)
		var z := _rng.randf_range(-world_size * 0.48, world_size * 0.48)
		var height := _rng.randf_range(0.55, 1.3)
		multimesh.set_instance_transform(i, Transform3D(Basis().rotated(Vector3.UP, _rng.randf_range(0.0, TAU)).scaled(Vector3(1.0, height, 1.0)), Vector3(x, 0.05, z)))
	var grass := MultiMeshInstance3D.new()
	grass.name = "GrassDetails"
	grass.multimesh = multimesh
	grass.material_override = grass_material
	add_child(grass)

func _build_river() -> void:
	var water := MeshInstance3D.new()
	water.name = "AncientRiver"
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1900.0, 78.0)
	water.mesh = mesh
	water.position = Vector3(0.0, 0.035, -270.0)
	water.rotation_degrees.y = -18.0
	var material := _mat(Color("#3b91a5"), 0.18, 0.22)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.88
	material.metallic = 0.18
	water.material_override = material
	add_child(water)
	var bank_material := _mat(Color("#b6a06c"))
	for side in [-1.0, 1.0]:
		var bank := MeshInstance3D.new()
		var bank_mesh := PlaneMesh.new()
		bank_mesh.size = Vector2(1900.0, 12.0)
		bank.mesh = bank_mesh
		bank.position = Vector3(0.0, 0.015, -270.0 + side * 46.0)
		bank.rotation_degrees.y = -18.0
		bank.material_override = bank_material
		add_child(bank)

func _build_forest() -> void:
	var trunk_materials := [_mat(Color("#553b2a")), _mat(Color("#674630")), _mat(Color("#765139"))]
	var leaf_materials := [_mat(Color("#294b2b")), _mat(Color("#3c6636")), _mat(Color("#557c3c"))]
	for i in range(tree_count):
		var x := _rng.randf_range(-world_size * 0.48, world_size * 0.48)
		var z := _rng.randf_range(-world_size * 0.48, world_size * 0.48)
		if Vector2(x, z).length() < 95.0 or absf(z + 0.32 * x + 270.0) < 80.0:
			continue
		var scale := _rng.randf_range(0.75, 1.55)
		var tree := Node3D.new()
		tree.position = Vector3(x, 0.0, z)
		add_child(tree)
		var trunk := MeshInstance3D.new()
		var trunk_mesh := CylinderMesh.new()
		trunk_mesh.top_radius = 0.22 * scale
		trunk_mesh.bottom_radius = 0.42 * scale
		trunk_mesh.height = 3.8 * scale
		trunk.mesh = trunk_mesh
		trunk.position.y = 1.9 * scale
		trunk.material_override = trunk_materials[i % trunk_materials.size()]
		tree.add_child(trunk)
		for crown_index in range(5):
			var crown := MeshInstance3D.new()
			var crown_mesh := SphereMesh.new()
			crown_mesh.radius = 1.45 * scale if crown_index == 0 else 1.0 * scale
			crown_mesh.height = crown_mesh.radius * 1.7
			crown.mesh = crown_mesh
			var offset := Vector3(_rng.randf_range(-0.85, 0.85), 3.6 * scale + _rng.randf_range(-0.2, 1.0) * scale, _rng.randf_range(-0.85, 0.85))
			crown.position = offset
			crown.material_override = leaf_materials[(i + crown_index) % leaf_materials.size()]
			tree.add_child(crown)

func _build_rocks() -> void:
	var materials := [_mat(Color("#727b78")), _mat(Color("#929b91")), _mat(Color("#626d68"))]
	for i in range(rock_count):
		var rock := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = _rng.randf_range(0.45, 1.8)
		mesh.height = mesh.radius * _rng.randf_range(0.55, 1.15)
		rock.mesh = mesh
		rock.position = Vector3(_rng.randf_range(-world_size * 0.46, world_size * 0.46), mesh.height * 0.42, _rng.randf_range(-world_size * 0.46, world_size * 0.46))
		rock.rotation = Vector3(_rng.randf_range(-0.3, 0.3), _rng.randf_range(0.0, TAU), _rng.randf_range(-0.3, 0.3))
		rock.material_override = materials[i % materials.size()]
		add_child(rock)

func _build_camp() -> void:
	var fire := MeshInstance3D.new()
	var flame := SphereMesh.new()
	flame.radius = 0.38
	flame.height = 0.9
	fire.mesh = flame
	fire.position = Vector3(0.0, 0.55, 0.0)
	var fire_material := _mat(Color("#ff9b32"), 0.35, 0.0)
	fire_material.emission_enabled = true
	fire_material.emission = Color("#ff6b18")
	fire_material.emission_energy_multiplier = 2.4
	fire.material_override = fire_material
	add_child(fire)
	var glow := OmniLight3D.new()
	glow.position = Vector3(0.0, 1.3, 0.0)
	glow.light_color = Color("#ff9b52")
	glow.light_energy = 2.0
	glow.omni_range = 12.0
	add_child(glow)
	for i in range(3):
		var log := MeshInstance3D.new()
		var log_mesh := CylinderMesh.new()
		log_mesh.top_radius = 0.12
		log_mesh.bottom_radius = 0.12
		log_mesh.height = 1.5
		log.mesh = log_mesh
		log.position = Vector3(0.0, 0.12, 0.0)
		log.rotation_degrees = Vector3(90.0, float(i) * 60.0, 0.0)
		log.material_override = _mat(Color("#553626"))
		add_child(log)

func _build_resources() -> void:
	var resource_types := ["wood", "stone", "food", "fish", "fruit", "berries", "clay", "herbs", "hide", "bone", "flint", "eggs"]
	for i in range(120):
		var resource := PrehistoricResource3D.new()
		resource.resource_type = resource_types[i % resource_types.size()]
		resource.amount_available = _rng.randi_range(2, 8)
		var x := _rng.randf_range(-world_size * 0.42, world_size * 0.42)
		var z := _rng.randf_range(-world_size * 0.42, world_size * 0.42)
		if Vector2(x, z).length() < 24.0 or absf(z + 0.32 * x + 270.0) < 58.0:
			x += 110.0
		resource.position = Vector3(x, 0.0, z)
		add_child(resource)

func _process(delta: float) -> void:
	_tribe_sync_timer += delta
	if _tribe_sync_timer >= 4.0:
		_tribe_sync_timer = 0.0
		_sync_tribe_residents()

func _sync_tribe_residents() -> void:
	if not is_instance_valid(TribePopulation):
		return
	var living_ids: Dictionary = {}
	for person in TribePopulation.residents:
		if not bool(person.get("alive", true)):
			continue
		var resident_id := int(person.get("id", -1))
		if resident_id < 0:
			continue
		living_ids[resident_id] = true
		if _resident_nodes.has(resident_id) and is_instance_valid(_resident_nodes[resident_id]):
			continue
		var resident := TribeResident3D.new()
		resident.setup(person)
		var angle := float(resident_id) * 2.399963
		var radius := 8.0 + float(resident_id % 5) * 1.65
		resident.position = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		add_child(resident)
		_resident_nodes[resident_id] = resident
	var remove_ids: Array = []
	for key in _resident_nodes:
		if not living_ids.has(int(key)) or not is_instance_valid(_resident_nodes[key]):
			if is_instance_valid(_resident_nodes[key]):
				_resident_nodes[key].queue_free()
			remove_ids.append(key)
	for key in remove_ids:
		_resident_nodes.erase(key)

func _build_wildlife() -> void:
	var species_list := ["wolf", "wolf", "wolf", "saber_tooth", "saber_tooth", "cave_bear", "mammoth", "deer", "deer", "deer"]
	for i in range(30):
		var animal := PrehistoricWildlife3D.new()
		animal.species = species_list[i % species_list.size()]
		var x := _rng.randf_range(-world_size * 0.42, world_size * 0.42)
		var z := _rng.randf_range(-world_size * 0.42, world_size * 0.42)
		if Vector2(x, z).length() < 95.0 or absf(z + 0.32 * x + 270.0) < 75.0:
			x += 160.0
		animal.position = Vector3(x, 0.0, z)
		add_child(animal)

func _build_barbarian_camps() -> void:
	var camp_positions := [Vector3(105, 0, 80), Vector3(-145, 0, 120), Vector3(220, 0, -90), Vector3(-260, 0, -140), Vector3(370, 0, 190), Vector3(-390, 0, 250)]
	for camp_index in range(camp_positions.size()):
		var camp := Node3D.new()
		camp.name = "BarbarianCamp_%02d" % camp_index
		camp.position = camp_positions[camp_index]
		add_child(camp)
		var ground := MeshInstance3D.new()
		var ground_mesh := CylinderMesh.new()
		ground_mesh.top_radius = 9.0
		ground_mesh.bottom_radius = 9.5
		ground_mesh.height = 0.18
		ground.mesh = ground_mesh
		ground.position.y = 0.05
		ground.material_override = _mat(Color("#756044"))
		camp.add_child(ground)
		for barricade_index in range(7):
			var barricade := MeshInstance3D.new()
			var log_mesh := BoxMesh.new()
			log_mesh.size = Vector3(2.8, 1.0, 0.35)
			barricade.mesh = log_mesh
			var angle := TAU * float(barricade_index) / 7.0
			barricade.position = Vector3(cos(angle) * 7.0, 0.55, sin(angle) * 7.0)
			barricade.rotation.y = -angle
			barricade.material_override = _mat(Color("#593a27"))
			camp.add_child(barricade)
		for raider_index in range(3 if camp_index % 2 == 0 else 2):
			var raider := PrehistoricBarbarian3D.new()
			raider.is_chief = camp_index % 3 == 0 and raider_index == 0
			raider.position = Vector3(cos(float(raider_index) * TAU / 3.0) * 3.0, 0.0, sin(float(raider_index) * TAU / 3.0) * 3.0)
			camp.add_child(raider)
