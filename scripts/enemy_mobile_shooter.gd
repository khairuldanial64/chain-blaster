extends "res://scripts/enemy_base.gd"


@export var bullet_scene: PackedScene = preload("res://scenes/enemy_bullet.tscn")
@export var fire_rate := 1.2
@export var bullet_speed := 400.0
@export var move_speed := 150.0
@export var preferred_distance := 350.0
@export var distance_tolerance := 60.0

@export var wall_avoidance_distance := 250.0  # starts steering away once this close to a wall
@export var wall_avoidance_strength := 1.0    # relative weight vs. the player-chasing steering

var fire_cooldown := 0.0

func _update_behavior(delta: float) -> void:
	_handle_movement()
	_handle_shooting(delta)
	_face_player()

func _handle_movement() -> void:
	var dist := distance_to_player()
	var dir := direction_to_player()
	var desired := Vector2.ZERO

	if dist > preferred_distance + distance_tolerance:
		desired = dir * move_speed
	elif dist < preferred_distance - distance_tolerance:
		desired = -dir * move_speed
	else:
		var strafe := dir.rotated(PI / 2)
		desired = strafe * move_speed * 0.6

	desired += _wall_avoidance_force()
	velocity = desired.limit_length(move_speed)

func _wall_avoidance_force() -> Vector2:
	if not has_node("/root/Arena"):
		return Vector2.ZERO

	var arena := get_node("/root/Arena")
	var bounds: Rect2 = arena.get_bounds()
	var force := Vector2.ZERO

	var dist_left := global_position.x - bounds.position.x
	var dist_right := (bounds.position.x + bounds.size.x) - global_position.x
	var dist_top := global_position.y - bounds.position.y
	var dist_bottom := (bounds.position.y + bounds.size.y) - global_position.y

	if dist_left < wall_avoidance_distance:
		force.x += (wall_avoidance_distance - dist_left) / wall_avoidance_distance
	if dist_right < wall_avoidance_distance:
		force.x -= (wall_avoidance_distance - dist_right) / wall_avoidance_distance
	if dist_top < wall_avoidance_distance:
		force.y += (wall_avoidance_distance - dist_top) / wall_avoidance_distance
	if dist_bottom < wall_avoidance_distance:
		force.y -= (wall_avoidance_distance - dist_bottom) / wall_avoidance_distance

	return force * move_speed * wall_avoidance_strength

func _face_player() -> void:
	# Triangle sprite assumed to point "up" by default — the +PI/2 offset
	# corrects for that so the tip always points at the player.
	if player:
		rotation = direction_to_player().angle() + PI / 2

func _handle_shooting(delta: float) -> void:
	fire_cooldown -= delta
	if fire_cooldown <= 0.0:
		_shoot()
		fire_cooldown = fire_rate

func _shoot() -> void:
	if bullet_scene == null or player == null:
		return

	var dir := direction_to_player()
	var bullet := bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.rotation = dir.angle()
	$EnemyLaserSound.pitch_scale = randf_range(0.75, 0.85) # Deeper pitch makes enemies feel heavier
	$EnemyLaserSound.play()

	if bullet.has_method("set_velocity"):
		bullet.set_velocity(dir * bullet_speed)
	elif "velocity" in bullet:
		bullet.velocity = dir * bullet_speed
