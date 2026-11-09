extends CharacterBody2D

@export var move_speed: float = 220.0

func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * move_speed
	move_and_slide()

func _draw() -> void:
	# Hình nhân vật tạm thời, sẽ thay bằng sprite/animation sau.
	draw_circle(Vector2.ZERO, 14.0, Color("#d9a066"))
	draw_circle(Vector2(-4.0, -3.0), 2.0, Color("#292018"))
	draw_circle(Vector2(4.0, -3.0), 2.0, Color("#292018"))
	draw_arc(Vector2(0.0, 1.0), 6.0, 0.25, PI - 0.25, 12, Color("#292018"), 1.5)
