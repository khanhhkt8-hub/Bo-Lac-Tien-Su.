extends Area2D
class_name ResourceNode

signal gathered(resource_type: String, amount: int)

@export_enum("wood", "stone", "food", "water") var resource_type: String = "wood"
@export_range(1, 99, 1) var amount_available: int = 5
@export var interaction_distance: float = 56.0

var _player: Node2D
var _interact_was_pressed := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var pressed := Input.is_key_pressed(KEY_E)
	if pressed and not _interact_was_pressed and global_position.distance_to(_player.global_position) <= interaction_distance:
		_gather()
	_interact_was_pressed = pressed

func _gather() -> void:
	if amount_available <= 0:
		return
	var amount := amount_available
	amount_available = 0
	if _player.has_method("collect_resource"):
		_player.collect_resource(resource_type, amount)
	gathered.emit(resource_type, amount)
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player = body

func _on_body_exited(body: Node2D) -> void:
	if body == _player:
		_player = null
