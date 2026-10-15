extends "res://scripts/enemy_base.gd"

# ── Attack 1: Dash ──────────────────────────────────────────
@export var dash_speed := 500.0
@export var dash_duration := 0.5
@export var dash_telegraph_time := 0.6
@export var dash_spin_speed := 20.0   # fast charge-up spin, telegraphs the incoming dash

# ── Attack 2: 8-directional spin shoot ─────────────────────
@export var spin_shoot_bullet_scene: PackedScene
@export var spin_shoot_duration := 3.0
@export var spin_shoot_rotation_speed := 3.0   # rad/sec, smooth continuous spin
@export var spin_shoot_fire_interval := 0.3
@export var spin_shoot_bullet_speed := 260.0

# ── Attack 3: Homing sine bullets from 4 body points ───────
@export var homing_bullet_scene: PackedScene
@export var homing_shoot_duration := 1.0
@export var homing_volley_count := 1      # how many times to fire the 4-bullet volley this phase
@export var homing_volley_interval := 0.5

# ── General attack cycle timing ────────────────────────────
@export var idle_duration := 1.5

enum State { IDLE, DASH_TELEGRAPH, DASHING, SPIN_SHOOT, HOMING_SHOOT }
var state: State = State.IDLE
var state_timer := 0.0
var attack_sequence := [State.DASH_TELEGRAPH, State.SPIN_SHOOT, State.HOMING_SHOOT]
var attack_index := 0

var dash_direction := Vector2.ZERO
var spin_shoot_fire_timer := 0.0
var homing_volleys_fired := 0
var homing_volley_timer := 0.0


func _ready() -> void:
	super._ready()
	state = State.IDLE
	state_timer = idle_duration

func _update_behavior(delta: float) -> void:
	state_timer -= delta

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			rotation = lerp_angle(rotation, direction_to_player().angle() + PI / 2, 2.0 * delta)
			if state_timer <= 0.0:
				_start_next_attack()

		State.DASH_TELEGRAPH:
			velocity = Vector2.ZERO
			rotation += dash_spin_speed * delta
			if state_timer <= 0.0:
				_start_dash()

		State.DASHING:
			velocity = dash_direction * dash_speed
			if state_timer <= 0.0:
				_enter_idle()

		State.SPIN_SHOOT:
			velocity = Vector2.ZERO
			rotation += spin_shoot_rotation_speed * delta
			spin_shoot_fire_timer -= delta
			if spin_shoot_fire_timer <= 0.0:
				_fire_radial_burst()
				spin_shoot_fire_timer = spin_shoot_fire_interval
			if state_timer <= 0.0:
				_enter_idle()

		State.HOMING_SHOOT:
			velocity = Vector2.ZERO
			homing_volley_timer -= delta
			if homing_volley_timer <= 0.0 and homing_volleys_fired < homing_volley_count:
				_fire_homing_volley()
				homing_volleys_fired += 1
				homing_volley_timer = homing_volley_interval
			if state_timer <= 0.0:
				_enter_idle()

func _start_next_attack() -> void:
	state = attack_sequence[attack_index]
	attack_index = (attack_index + 1) % attack_sequence.size()

	match state:
		State.DASH_TELEGRAPH:
			$TelegraphSound.play()
			state_timer = dash_telegraph_time
		State.SPIN_SHOOT:
			state_timer = spin_shoot_duration
			spin_shoot_fire_timer = 0.0
		State.HOMING_SHOOT:
			state_timer = homing_shoot_duration
			homing_volleys_fired = 0
			homing_volley_timer = 0.0

func _start_dash() -> void:
	$DashSound.play()
	state = State.DASHING
	state_timer = dash_duration
	dash_direction = direction_to_player()

func _enter_idle() -> void:
	state = State.IDLE
	state_timer = idle_duration

func _fire_radial_burst() -> void:
	if spin_shoot_bullet_scene == null:
		return
		
	$EnemyLaserSound.play()
	
	var directions_count := 8
	for i in directions_count:
		var angle := rotation + (TAU / directions_count) * i
		var dir := Vector2.RIGHT.rotated(angle)
		var bullet := spin_shoot_bullet_scene.instantiate()
		bullet.global_position = global_position
		bullet.rotation = dir.angle()
		get_tree().current_scene.add_child(bullet)
		if bullet.has_method("set_velocity"):
			bullet.set_velocity(dir * spin_shoot_bullet_speed)
		elif "velocity" in bullet:
			bullet.velocity = dir * spin_shoot_bullet_speed

func _fire_homing_volley() -> void:
	if homing_bullet_scene == null:
		return
	$EnemyLaserSound.play()
	# Add 4 Marker2D children to your boss scene named exactly these, positioned
	# wherever on the body you want the bullets to emit from (e.g. 4 limbs/corners).
	var point_names := ["AttackPoint1", "AttackPoint2", "AttackPoint3", "AttackPoint4"]
	for point_name in point_names:
		var spawn_point := get_node_or_null(point_name)
		var spawn_pos: Vector2 = spawn_point.global_position if spawn_point else global_position

		var bullet := homing_bullet_scene.instantiate()
		bullet.global_position = spawn_pos
		get_tree().current_scene.add_child(bullet)
		if "forward_direction" in bullet:
			bullet.forward_direction = direction_to_player()
