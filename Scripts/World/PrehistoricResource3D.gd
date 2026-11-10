extends Node3D
class_name PrehistoricResource3D

@export var resource_type: String = "wood"
@export_range(1, 99, 1) var amount_available: int = 5
var _collected := false

const COLORS := {
	"wood": Color("#805334"), "stone": Color("#929b9b"),
	"food": Color("#a9a34c"), "fish": Color("#438eb8"),
	"fruit": Color("#d66b3d"), "berries": Color("#a83e66"),
	"chicken": Color("#e4c56b"), "duck": Color("#b7a66a"),
	"eggs": Color("#eee0b4"), "clay": Color("#a66b51"),
	"herbs": Color("#5d9a4d"), "hide": Color("#9b7654"),
	"bone": Color("#ded2ad"), "flint": Color("#6d8790"),
	"ore": Color("#858d91"), "reeds": Color("#6d9b4d")
}

func _ready() -> void:
	add_to_group("resources_3d")
	_build_visual()

func gather(player: Node) -> bool:
	if _collected or amount_available <= 0 or player == null or not player.has_method("collect_resource"):
		return false
	_collected = true
	player.collect_resource(resource_type, amount_available)
	queue_free()
	return true

func _build_visual() -> void:
	var color: Color = COLORS.get(resource_type, Color("#a18b62"))
	var shadow := MeshInstance3D.new()
	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.65
	shadow_mesh.bottom_radius = 0.72
	shadow_mesh.height = 0.035
	shadow.mesh = shadow_mesh
	shadow.position.y = 0.025
	shadow.material_override = _mat(Color(0.05, 0.07, 0.04, 0.32))
	add_child(shadow)
	var item := MeshInstance3D.new()
	item.name = "ResourceModel"
	match resource_type:
		"wood", "reeds", "herbs":
			var mesh := CylinderMesh.new()
			mesh.top_radius = 0.13
			mesh.bottom_radius = 0.2
			mesh.height = 1.05
			item.mesh = mesh
			item.rotation_degrees.z = 18.0
		"food", "fruit", "berries", "eggs", "chicken", "duck", "fish":
			var mesh := SphereMesh.new()
			mesh.radius = 0.43
			mesh.height = 0.72
			item.mesh = mesh
			item.scale = Vector3(1.0, 0.8, 1.25)
		_:
			var mesh := SphereMesh.new()
			mesh.radius = 0.48
			mesh.height = 0.78
			item.mesh = mesh
			item.scale = Vector3(1.25, 0.8, 0.9)
	item.position.y = 0.48
	item.material_override = _mat(color)
	add_child(item)
	var marker := MeshInstance3D.new()
	var marker_mesh := CylinderMesh.new()
	marker_mesh.top_radius = 0.48
	marker_mesh.bottom_radius = 0.48
	marker_mesh.height = 0.035
	marker.mesh = marker_mesh
	marker.position.y = 0.08
	marker.material_override = _mat(color.darkened(0.35))
	add_child(marker)

func _mat(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.88
	return material
