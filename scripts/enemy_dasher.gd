extends "res://scripts/enemy_base.gd"

@export var drift_speed := 80.0
@export var dash_speed := 500.0
@export var dash_duration := 0.5
@export var dash_cooldown_time := 1.8
@export var dash_telegraph_time := 0.5   # wind-up before dashing (readable warning)
@export var slow_spin_speed := 2.0       # rad/sec while drifting/dashing/cooling down
@export var fast_spin_speed := 25.0      # rad/sec while charging up the dash

enum State { DRIFTING, TELEGRAPHING, DASHING, COOLDOWN }
var state: State = State.DRIFTING
var state_timer := 0.0
var dash_direction := Vector2.ZERO

func _update_behavior(delta: float) -> void:
	state_timer -= delta
	_update_spin(delta)

	match state:
		State.DRIFTING:
			velocity = direction_to_player() * drift_speed
			if state_timer <= 0.0 or distance_to_player() < 400.0:
				_start_telegraph()

		State.TELEGRAPHING:
			velocity = velocity.move_toward(Vector2.ZERO, drift_speed * delta * 4.0)
			if state_timer <= 0.0:
				_start_dash()

		State.DASHING:
			velocity = dash_direction * dash_speed
			if state_timer <= 0.0:
				_start_cooldown()

		State.COOLDOWN:
			velocity = velocity.move_toward(Vector2.ZERO, drift_speed * delta * 4.0)
			if state_timer <= 0.0:
				state = State.DRIFTING
				state_timer = 1.0

func _update_spin(delta: float) -> void:
	# Pentagon visual spin: fast "charging" spin during telegraph, slow otherwise.
	var spin_speed := fast_spin_speed if state == State.TELEGRAPHING else slow_spin_speed
	rotation += spin_speed * delta

func _start_telegraph() -> void:
	state = State.TELEGRAPHING
	$TelegraphSound.play()
	state_timer = dash_telegraph_time

func _start_dash() -> void:
	state = State.DASHING
	state_timer = dash_duration
	$DashSound.play()
	dash_direction = direction_to_player()

func _start_cooldown() -> void:
	state = State.COOLDOWN
	state_timer = dash_cooldown_time
