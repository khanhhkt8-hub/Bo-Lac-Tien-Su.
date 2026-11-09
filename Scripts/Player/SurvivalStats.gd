extends Node
class_name SurvivalStats

signal stats_changed(health: float, hunger: float, thirst: float)
signal player_died

@export var max_health: float = 100.0
@export var max_hunger: float = 100.0
@export var max_thirst: float = 100.0
@export var hunger_drain_per_minute: float = 1.5
@export var thirst_drain_per_minute: float = 2.5
@export var starvation_damage_per_second: float = 2.0
@export var dehydration_damage_per_second: float = 4.0

var health: float
var hunger: float
var thirst: float
var _death_emitted := false

func _ready() -> void:
	health = max_health
	hunger = max_hunger
	thirst = max_thirst
	_emit_stats()

func _process(delta: float) -> void:
	hunger = maxf(0.0, hunger - hunger_drain_per_minute * delta / 60.0)
	thirst = maxf(0.0, thirst - thirst_drain_per_minute * delta / 60.0)

	if hunger <= 0.0:
		health = maxf(0.0, health - starvation_damage_per_second * delta)
	if thirst <= 0.0:
		health = maxf(0.0, health - dehydration_damage_per_second * delta)

	if health <= 0.0 and not _death_emitted:
		_death_emitted = true
		player_died.emit()

	_emit_stats()

func eat(food_value: float) -> void:
	hunger = minf(max_hunger, hunger + maxf(0.0, food_value))
	_emit_stats()

func drink(water_value: float) -> void:
	thirst = minf(max_thirst, thirst + maxf(0.0, water_value))
	_emit_stats()

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - maxf(0.0, amount))
	_emit_stats()
	if health <= 0.0 and not _death_emitted:
		_death_emitted = true
		player_died.emit()

func _emit_stats() -> void:
	stats_changed.emit(health, hunger, thirst)
