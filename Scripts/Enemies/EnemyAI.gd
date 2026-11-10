extends CharacterBody2D
class_name EnemyAI

signal defeated(enemy: EnemyAI)

 enum AIState { PATROL, CHASE, ATTACK, RETURN }

@export var enemy_name: String = "Enemy"
@export var max_health: float = 60.0
@export var move_speed: float = 82.0
@export var detection_range: float = 210.0
@export var attack_range: float = 30.0
@export var attack_damage: float = 8.0
@export var attack_cooldown: float = 1.4
@export var patrol_radius: float = 110.0

var health: float
var state: AIState = AIState.PATROL
var home_position: Vector2
var patrol_target: Vector2
var target: Node2D
var attack_timer: float = 0.0
var retarget_timer: float = 0.0
var slow_seconds: float = 0.0
var slow_multiplier: float = 1.0
var poison_seconds: float = 0.0
var poison_damage: float = 0.0
var poison_tick_timer: float = 0.0

func _ready() -> void:
	health = max_health
	home_position = global_position
	_choose_patrol_point()
	add_to_group("enemies")

func _physics_process(delta: float) -> void:
	attack_timer = maxf(0.0, attack_timer - delta)
	slow_seconds = maxf(0.0, slow_seconds - delta)
	if slow_seconds <= 0.0:
		slow_multiplier = 1.0
	poison_seconds = maxf(0.0, poison_seconds - delta)
	if poison_seconds > 0.0:
		poison_tick_timer -= delta
		if poison_tick_timer <= 0.0:
			poison_tick_timer = 1.0
			take_damage(poison_damage)
	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = 0.25
		_update_target()
	_update_state()
	_move_ai(delta)
	move_and_slide()
	queue_redraw()

func _update_target() -> void:
	if is_instance_valid(target):
		if global_position.distance_to(target.global_position) > detection_range * 1.45:
			target = null
	if not is_instance_valid(target):
		var player := get_tree().get_first_node_in_group("player") as Node2D
		if is_instance_valid(player) and global_position.distance_to(player.global_position) <= detection_range:
			target = player
			_on_target_detected(player)

func _update_state() -> void:
	if is_instance_valid(target):
		var distance := global_position.distance_to(target.global_position)
		if distance <= attack_range:
			state = AIState.ATTACK
		else:
			state = AIState.CHASE
	elif global_position.distance_to(home_position) > patrol_radius * 1.8:
		state = AIState.RETURN
	else:
		state = AIState.PATROL

func _move_ai(_delta: float) -> void:
	var destination := global_position
	match state:
		AIState.CHASE:
			if is_instance_valid(target):
				destination = target.global_position
		AIState.ATTACK:
			velocity = Vector2.ZERO
			_try_attack()
			return
		AIState.RETURN:
			destination = home_position
		AIState.PATROL:
			destination = patrol_target
			if global_position.distance_to(patrol_target) < 12.0:
				_choose_patrol_point()
	var direction := global_position.direction_to(destination)
	velocity = direction * move_speed * slow_multiplier
	if direction.length_squared() > 0.01:
		rotation = direction.angle()

func _try_attack() -> void:
	if attack_timer > 0.0 or not is_instance_valid(target):
		return
	attack_timer = attack_cooldown
	if target.has_method("take_damage"):
		target.take_damage(attack_damage)

func _choose_patrol_point() -> void:
	var angle := randf() * TAU
	var distance := randf_range(patrol_radius * 0.25, patrol_radius)
	patrol_target = home_position + Vector2.RIGHT.rotated(angle) * distance

func _on_target_detected(_new_target: Node2D) -> void:
	pass


func apply_slow(duration: float, multiplier: float) -> void:
	slow_seconds = maxf(slow_seconds, duration)
	slow_multiplier = minf(slow_multiplier, clampf(multiplier, 0.1, 1.0))

func apply_poison(duration: float, damage_per_second: float) -> void:
	poison_seconds = maxf(poison_seconds, duration)
	poison_damage = maxf(poison_damage, damage_per_second)
	poison_tick_timer = minf(poison_tick_timer, 1.0) if poison_tick_timer > 0.0 else 1.0

func take_damage(amount: float) -> void:
	health = maxf(0.0, health - maxf(0.0, amount))
	if health <= 0.0 and not is_queued_for_deletion():
		defeated.emit(self)
		queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, Color("#76513b"))
	draw_circle(Vector2(-4.0, -3.0), 2.0, Color("#211b17"))
	draw_circle(Vector2(4.0, -3.0), 2.0, Color("#211b17"))
	draw_rect(Rect2(Vector2(-15.0, -23.0), Vector2(30.0, 4.0)), Color("#302b27"))
	draw_rect(Rect2(Vector2(-15.0, -23.0), Vector2(30.0 * health / max_health, 4.0)), Color("#c84b3c"))
