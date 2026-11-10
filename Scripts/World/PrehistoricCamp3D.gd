extends Node3D
class_name PrehistoricCamp3D

@export var camp_index := 0
@export var required_guards := 3
var is_captured := false
var _banner: MeshInstance3D
var _status_label: Label3D

func _ready() -> void:
	add_to_group("barbarian_camps_3d")
	var progress := ConfigFile.new()
	if progress.load("user://bo_lac_camps.cfg") == OK:
		is_captured = bool(progress.get_value("camps", str(camp_index), false))
	_build_camp()

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.9
	return material

func _build_camp() -> void:
	var ground := MeshInstance3D.new()
	var ground_mesh := CylinderMesh.new()
	ground_mesh.top_radius = 9.0
	ground_mesh.bottom_radius = 9.5
	ground_mesh.height = 0.18
	ground.mesh = ground_mesh
	ground.position.y = 0.05
	ground.material_override = _mat(Color("#756044"))
	add_child(ground)
	for index in range(7):
		var barricade := MeshInstance3D.new()
		var log_mesh := BoxMesh.new()
		log_mesh.size = Vector3(2.8, 1.0, 0.35)
		barricade.mesh = log_mesh
		var angle := TAU * float(index) / 7.0
		barricade.position = Vector3(cos(angle) * 7.0, 0.55, sin(angle) * 7.0)
		barricade.rotation.y = -angle
		barricade.material_override = _mat(Color("#593a27"))
		add_child(barricade)
	_banner = MeshInstance3D.new()
	var banner_mesh := BoxMesh.new()
	banner_mesh.size = Vector3(1.1, 1.4, 0.08)
	_banner.mesh = banner_mesh
	_banner.position = Vector3(0, 2.0, -4.0)
	_banner.material_override = _mat(Color("#a52f28"))
	add_child(_banner)
	_status_label = Label3D.new()
	_status_label.position = Vector3(0, 4.0, 0)
	_status_label.font_size = 48
	_status_label.text = "TRẠI MAN RỢ %d" % (camp_index + 1)
	add_child(_status_label)
	if is_captured:
		_status_label.text = "ĐÃ CHIẾM - TRẠI %d" % (camp_index + 1)
		_banner.material_override = _mat(Color("#d6ad55"))
		return
	for index in range(required_guards):
		var guard := PrehistoricBarbarian3D.new()
		guard.is_chief = camp_index % 3 == 0 and index == 0
		guard.position = Vector3(cos(float(index) * TAU / float(required_guards)) * 3.0, 0.0, sin(float(index) * TAU / float(required_guards)) * 3.0)
		add_child(guard)

func get_remaining_guards() -> int:
	var count := 0
	for guard in get_children():
		if guard is PrehistoricBarbarian3D and not guard.is_queued_for_deletion():
			count += 1
	return count

func can_capture() -> bool:
	return not is_captured and get_remaining_guards() == 0

func capture() -> bool:
	if not can_capture():
		return false
	is_captured = true
	_status_label.text = "ĐÃ CHIẾM"
	_banner.material_override = _mat(Color("#d6ad55"))
	var progress := ConfigFile.new()
	progress.load("user://bo_lac_camps.cfg")
	progress.set_value("camps", str(camp_index), true)
	progress.save("user://bo_lac_camps.cfg")
	return true
