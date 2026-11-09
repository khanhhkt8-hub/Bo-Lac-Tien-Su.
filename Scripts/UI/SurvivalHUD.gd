extends CanvasLayer

@export var player_path: NodePath = NodePath("../Player")

var _stats_label: Label
var _inventory_label: Label
var _player: Node

func _ready() -> void:
	_player = get_node_or_null(player_path)
	var panel := PanelContainer.new()
	panel.position = Vector2(16, 16)
	panel.custom_minimum_size = Vector2(290, 96)
	add_child(panel)
	var column := VBoxContainer.new()
	panel.add_child(column)
	_stats_label = Label.new()
	_stats_label.text = "Máu: -- | Đói: -- | Khát: --"
	column.add_child(_stats_label)
	_inventory_label = Label.new()
	_inventory_label.text = "Túi đồ: trống"
	column.add_child(_inventory_label)
	if _player != null:
		if _player.survival_stats != null:
			_player.survival_stats.stats_changed.connect(_on_stats_changed)
			_on_stats_changed(_player.survival_stats.health, _player.survival_stats.hunger, _player.survival_stats.thirst)
		if _player.inventory != null:
			_player.inventory.inventory_changed.connect(_on_inventory_changed)
			_on_inventory_changed(_player.inventory.items)

func _on_stats_changed(health: float, hunger: float, thirst: float) -> void:
	_stats_label.text = "Máu: %d | Đói: %d | Khát: %d" % [roundi(health), roundi(hunger), roundi(thirst)]

func _on_inventory_changed(items: Dictionary) -> void:
	if items.is_empty():
		_inventory_label.text = "Túi đồ: trống"
		return
	var parts: PackedStringArray = []
	for item_id in items:
		parts.append("%s: %d" % [str(item_id), int(items[item_id])])
	_inventory_label.text = "Túi đồ: " + " | ".join(parts)
