extends "res://scripts/enemy_base.gd"

@export var bullet_scene: PackedScene = preload("res://scenes/enemy_bullet.tscn")
@export var fire_rate := 1.5           # seconds between shots
@export var bullet_speed := 350.0
@export var fire_range := 600.0        # only shoots if player is within this distance

var fire_cooldown := 0.0

func _update_behavior(delta: float) -> void:
	# Stationary: no movement, velocity stays zero
	velocity = Vector2.ZERO

	fire_cooldown -= delta
	if fire_cooldown <= 0.0 and distance_to_player() <= fire_range:
		_shoot()
		fire_cooldown = fire_rate

func _shoot() -> void:
	if bullet_scene == null or player == null:
		return
	$EnemyLaserSound.pitch_scale = randf_range(0.75, 0.85) # Deeper pitch makes enemies feel heavier
	$EnemyLaserSound.play()

	for child in $Sprite2D/Node2D.get_children():
		var bullet = bullet_scene.instantiate()
		bullet.global_position = child.global_position
		var dir = (child.global_position - global_position).normalized()
		bullet.direction = dir
		bullet.rotation = dir.angle()
		get_tree().root.add_child(bullet)

		if bullet.has_method("set_velocity"):
			bullet.set_velocity(dir * bullet_speed)
		elif "velocity" in bullet:
			bullet.velocity = dir * bullet_speed
