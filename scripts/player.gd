extends CharacterBody2D

# ── Tunables ────────────────────────────────────────────────
const THRUST_POWER := 800.0        # acceleration when thrusting forward
const REVERSE_THRUST_POWER := 400.0 # weaker reverse thrust (optional, feels good for control)
const DRAG := 0.985                 # velocity multiplier per physics frame (space "friction")
const MAX_SPEED := 200.0
const ROTATION_SPEED := 4.5         # radians/sec turn rate
const STRAFE_POWER := 600.0         # set to 0 if you don't want strafing, only rotate+thrust
@export var bullet_scene: PackedScene = preload("res://scenes/player_bullet.tscn") 
@export var fire_rate := 0.3            # seconds between shots (lower = faster)
@export var bullet_speed := 900.0

@export var muzzle_flash_scene: PackedScene = preload("res://scenes/muzzle_flash.tscn")

var fire_cooldown := 0.0
var aim_direction := Vector2.UP
@export var health := 3
@export var max_health := 3

@export var death_particles: PackedScene = preload("res://scenes/death_particles.tscn")

# ── Post-hit invincibility (blinking i-frames after taking damage) ─
@export var invincibility_duration := 1.5
@export var blink_interval := 0.1
var is_invincible := false
var invincibility_timer := 0.0
var blink_timer := 0.0

# ── Dash / boost (stub for later — wire up when you build it) ─
const DASH_SPEED := 700.0
const DASH_DURATION := 0.6
var is_dashing := false
var dash_timer := 0.0
var can_dash := true

signal player_died
signal health_changed(current_health: int, max_health: int)


# ── Weapon State Machine ────────────────────────────────────
enum WeaponType { DEFAULT, SPREAD, SMG }
var current_weapon := WeaponType.DEFAULT
var powerup_timer := 0.0
var powerup_max_duration := 1.0

@export var spread_bullet_count := 5
@export var spread_angle_degrees := 30.0

# ── SMG Tunables ────────────────────────────────────────────
@export var smg_fire_rate := 0.08      # Shoots insanely fast! (seconds between shots)
@export var smg_spray_angle := 12.0    # Maximum randomized angle deviation in degrees


func _ready() -> void:
	add_to_group("player")
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	_update_aim()
	_face_cursor()
	fire_cooldown -= delta
	if Input.is_action_pressed("fire") and fire_cooldown <= 0.0:
		_shoot() # Cooldown duration calculation is now managed internally inside _shoot()
		
	# Process active powerup timers smoothly
	if current_weapon != WeaponType.DEFAULT:
		powerup_timer -= delta
		if powerup_timer <= 0.0:
			current_weapon = WeaponType.DEFAULT # Revert back to basic weapon
			
	#_handle_rotation(delta)
	_handle_thrust(delta)
	_handle_dash(delta)
	_apply_drag()
	_clamp_speed()
	move_and_slide()
	_enforce_arena_bounds()
	_handle_invincibility(delta)

func _handle_rotation(delta: float) -> void:
	var turn := Input.get_axis("turn_left", "turn_right")
	rotation += turn * ROTATION_SPEED * delta
	if Input.is_action_just_pressed("turn_left"):
		$RightThruster.emitting = true
	if Input.is_action_just_pressed("turn_right"):
		$LeftThruster.emitting = true

func _handle_thrust(delta: float) -> void:
	if is_dashing:
		return

	var forward := Vector2.UP.rotated(rotation)
	var thrust_input := Input.get_action_strength("thrust_forward")
	var reverse_input := Input.get_action_strength("thrust_reverse")

	if thrust_input > 0.0:
		velocity += forward * THRUST_POWER * thrust_input * delta
	if reverse_input > 0.0:
		velocity -= forward * REVERSE_THRUST_POWER * reverse_input * delta
		
	$LeftThruster.emitting = thrust_input > 0.0
	$RightThruster.emitting = thrust_input > 0.0

	# Optional strafing (remove this block if you want pure Asteroids-style rotate+thrust only)
	if STRAFE_POWER > 0.0:
		var right := Vector2.RIGHT.rotated(rotation)
		var strafe_input := Input.get_axis("strafe_left", "strafe_right")
		if strafe_input != 0.0:
			velocity += right * STRAFE_POWER * strafe_input * delta

func _handle_dash(delta: float) -> void:
	if is_dashing:
		$LeftThruster.color = Color(0.964, 0.576, 0.0, 1.0)
		$RightThruster.color = Color(0.964, 0.576, 0.0, 1.0)
		$LeftThruster.emitting = is_dashing
		$RightThruster.emitting = is_dashing
		dash_timer -= delta
		if dash_timer <= 0.0:
			$LeftThruster.color = Color(1.0, 1.0, 1.0, 1.0)
			$RightThruster.color = Color(1.0, 1.0, 1.0, 1.0)
			is_dashing = false
		return

	if can_dash and Input.is_action_just_pressed("dash"):
		$BoostSound.play()
		var dash_dir := Vector2.UP.rotated(rotation)
		velocity = dash_dir * DASH_SPEED
		is_dashing = true
		dash_timer = DASH_DURATION
		can_dash = false
		# Hook your dash cooldown/i-frames here, e.g.:
		# $DashCooldownTimer.start()
		# $Hurtbox.monitoring = false (re-enable when dash ends)

func _apply_drag() -> void:
	velocity *= DRAG

func _clamp_speed() -> void:
	if not is_dashing and velocity.length() > MAX_SPEED:
		velocity = velocity.normalized() * MAX_SPEED

func _handle_invincibility(delta: float) -> void:
	if not is_invincible:
		return

	invincibility_timer -= delta
	blink_timer -= delta

	if blink_timer <= 0.0:
		blink_timer = blink_interval
		modulate.a = 0.3 if modulate.a >= 1.0 else 1.0

	if invincibility_timer <= 0.0:
		is_invincible = false
		modulate.a = 1.0

func reset_dash() -> void:
	can_dash = true

func _on_dash_timer_timeout() -> void:
	reset_dash() 

func _update_aim() -> void:
	var mouse_pos := get_global_mouse_position()
	aim_direction = (mouse_pos - global_position).normalized()

func _face_cursor() -> void:
	# Rotates a visual turret/sprite to face the mouse, independent of ship facing.
	# If you want the WHOLE ship to face the mouse instead of just a turret,
	rotation = aim_direction.angle() + PI/2
	# (the +PI/2 offset assumes your sprite's "up" is the nose — adjust to match your art).
	# rotation = aim_direction.angle() + PI / 2

func _shoot() -> void:
	if bullet_scene == null:
		push_warning("Ship shooting: no bullet_scene assigned!")
		return

	# Handle weapon fire rates and sounds based on the active weapon
	if current_weapon == WeaponType.SMG:
		$LaserSound.pitch_scale = randf_range(1.2, 1.4) # Higher pitch sounds faster/lighter
		fire_cooldown = smg_fire_rate
	else:
		$LaserSound.pitch_scale = randf_range(0.9, 1.1)
		fire_cooldown = fire_rate
		
	$LaserSound.play()

	# Spawn muzzle flash
	if muzzle_flash_scene:
		var flash := muzzle_flash_scene.instantiate()
		flash.global_position = $Muzzle.global_position
		flash.rotation = aim_direction.angle()
		get_tree().current_scene.add_child(flash)

	# ── WEAPON STATE LOGIC ───────────────────────────────────
	match current_weapon:
		WeaponType.DEFAULT:
			_spawn_single_bullet(aim_direction.angle())
			
		WeaponType.SPREAD:
			var total_spread_rad := deg_to_rad(spread_angle_degrees)
			var start_angle := aim_direction.angle() - (total_spread_rad / 2.0)
			var angle_step := total_spread_rad / (spread_bullet_count - 1)
			
			for i in spread_bullet_count:
				var final_angle = start_angle + (i * angle_step)
				_spawn_single_bullet(final_angle)
				
		WeaponType.SMG:
			# Calculate a completely randomized angle offset to simulate gun spray
			var max_spray_rad := deg_to_rad(smg_spray_angle)
			var random_offset := randf_range(-max_spray_rad / 2.0, max_spray_rad / 2.0)
			
			var final_angle = aim_direction.angle() + random_offset
			_spawn_single_bullet(final_angle)

## Quick helper function to prevent repeating copy-pasted spawn logic
func _spawn_single_bullet(angle_radians: float) -> void:
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = $Muzzle.global_position
	bullet.rotation = angle_radians
	
	# ── DETERMINE AND INJECT BULLET TINT COLOR ───────────────
	# Check the active weapon enum state and assign the matching hex color
	var active_color := Color("#ffffff") # Default white for basic weapon
	
	match current_weapon:
		WeaponType.SPREAD:
			active_color = Color("ff9200ff") # Matches Cyan PowerUpBar
		WeaponType.SMG:
			active_color = Color("ba01afff") # Matches Synthwave Pink PowerUpBar
			
	# Apply the color tint directly to the bullet node
	bullet.modulate = active_color
	# ─────────────────────────────────────────────────────────
	
	var bullet_dir := Vector2.RIGHT.rotated(angle_radians)
	if "velocity" in bullet:
		bullet.velocity = bullet_dir * bullet_speed
	elif bullet.has_method("set_velocity"):
		bullet.set_velocity(bullet_dir * bullet_speed)


			
## Activates the spread pattern weapon system for a limited time duration
func activate_spread_weapon(duration) -> void:
	if current_weapon != WeaponType.DEFAULT:
		pass
	else:
		current_weapon = WeaponType.SPREAD
		powerup_timer = duration
		powerup_max_duration = duration
		
func activate_smg_weapon(duration) -> void:
	if current_weapon != WeaponType.DEFAULT:
		pass
	else:
		current_weapon = WeaponType.SMG
		powerup_timer = duration
		powerup_max_duration = duration

		
func take_damage(amount := 0) -> void:
	if is_dashing or is_invincible or is_dead or combat_disabled:
		return
	$HurtSound.play()
	health -= amount
	health_changed.emit(health, max_health)
	
	if has_node("/root/Juice"):
		var juice := get_node("/root/Juice")
		juice.screen_shake(0.6)
		juice.hit_stop(0.08, 0.05)
		
	if health <= 0:
		die()
	else:
		is_invincible = true
		invincibility_timer = invincibility_duration
		blink_timer = 0.0
		
var is_dead := false
 
func die() -> void:
	
	if is_dead:
		return
	is_dead = true
	
	emit_signal("player_died")
	set_physics_process(false)
	visible = false
	ScoreManager.save_high_score()
	if has_node("/root/ComboManager"):
		get_node("/root/ComboManager").break_combo()
		
	if death_particles:
		var fx := death_particles.instantiate()
		fx.global_position = global_position
		get_tree().current_scene.add_child(fx)
		
func heal(amount: int):
	if health < max_health:
		health += amount
		health_changed.emit(health, max_health)
	else:
		return

func _enforce_arena_bounds() -> void:
	if not has_node("/root/Arena"):
		return
	var arena := get_node("/root/Arena")
	var margin := 20.0  # roughly half the ship's collision size, adjust to match your sprite
 
	var bounds: Rect2 = arena.get_bounds()
	if global_position.x < bounds.position.x + margin or global_position.x > bounds.position.x + bounds.size.x - margin:
		velocity.x = 0.0
	if global_position.y < bounds.position.y + margin or global_position.y > bounds.position.y + bounds.size.y - margin:
		velocity.y = 0.0
 
	global_position = arena.clamp_position(global_position, margin)
var combat_disabled := false  # set true on victory — player stops taking damage but stays alive-looking
func disable_combat() -> void:
	combat_disabled = true
