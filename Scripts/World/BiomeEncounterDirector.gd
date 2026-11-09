extends Node2D
## Spawns a small, local set of biome resources and wildlife when a region is entered.

const RESOURCE_SCENE: PackedScene = preload("res://Scenes/ResourceNode.tscn")
const ANIMAL_SCENE: PackedScene = preload("res://Scenes/PrehistoricAnimal.tscn")

const REGION_CONTENT := {
	"heartland": {
		"resources": ["wood", "stone", "food", "water"],
		"animals": ["wolf"]
	},
	"primeval_forest": {
		"resources": ["wood", "wood", "berries", "herbs", "hide"],
		"animals": ["wolf", "wolf", "saber_tooth"]
	},
	"grassland": {
		"resources": ["food", "food", "hide", "bone", "flint"],
		"animals": ["mammoth", "wolf", "wolf"]
	},
	"swampland": {
		"resources": ["water", "herbs", "herbs", "berries", "reeds"],
		"animals": ["cave_bear", "wolf"]
	},
	"cavern": {
		"resources": ["stone", "flint", "flint", "bone", "ore"],
		"animals": ["cave_bear", "saber_tooth"]
	},
	"frostlands": {
		"resources": ["ice", "hide", "bone", "meat", "meat"],
		"animals": ["mammoth", "cave_bear"]
	}
}

var active_region_id := ""

func _ready() -> void:
	RegionSystem.region_changed.connect(_on_region_changed)

func _on_region_changed(region_id: String, _data: Dictionary) -> void:
	if region_id == active_region_id:
		return
	active_region_id = region_id
	_clear_previous_encounter()
	if region_id.is_empty() or not REGION_CONTENT.has(region_id):
		return
	_spawn_region_content(region_id)

func _clear_previous_encounter() -> void:
	for node in get_tree().get_nodes_in_group("biome_spawned"):
		if is_instance_valid(node):
			node.queue_free()

func _spawn_region_content(region_id: String) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if not is_instance_valid(player):
		return
	var content: Dictionary = REGION_CONTENT[region_id]
	var resource_types: Array = content.get("resources", [])
	var animal_types: Array = content.get("animals", [])
	for i in range(resource_types.size()):
		var resource := RESOURCE_SCENE.instantiate() as ResourceNode
		resource.resource_type = str(resource_types[i])
		resource.amount_available = randi_range(3, 7)
		add_child(resource)
		resource.global_position = _find_spawn_position(player.global_position, region_id, 150.0 + float(i) * 52.0)
		resource.add_to_group("biome_spawned")
	for i in range(animal_types.size()):
		var animal := ANIMAL_SCENE.instantiate() as PrehistoricAnimal
		animal.species = str(animal_types[i])
		animal.passive_until_attacked = animal.species == "mammoth"
		add_child(animal)
		animal.global_position = _find_spawn_position(player.global_position, region_id, 330.0 + float(i) * 75.0)
		animal.add_to_group("biome_spawned")

func _find_spawn_position(origin: Vector2, region_id: String, preferred_distance: float) -> Vector2:
	var region_data: Dictionary = RegionSystem.get_region_data(region_id)
	var center: Vector2 = region_data.get("center", origin)
	var radius: float = float(region_data.get("radius", 600.0))
	for attempt in range(18):
		var angle := randf() * TAU
		var distance := randf_range(preferred_distance * 0.55, preferred_distance)
		var candidate := origin + Vector2.RIGHT.rotated(angle) * distance
		if candidate.distance_to(center) <= radius * 0.92:
			return candidate
	return center + Vector2.RIGHT.rotated(randf() * TAU) * radius * 0.45
