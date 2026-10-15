extends "res://scripts/enemy_base.gd"

@export var spread_duration := 15.0
@export var wander_speed := 50.0
@export var direction_change_interval := 2.5

var wander_direction := Vector2.ZERO
var wander_timer := 0.0

func _ready() -> void:
	super._ready()
	_pick_new_direction()

func _update_behavior(delta: float) -> void:
	wander_timer -= delta
	if wander_timer <= 0.0:
		_pick_new_direction()
	velocity = wander_direction * wander_speed

func _pick_new_direction() -> void:
	var angle := randf_range(0.0, TAU)
	wander_direction = Vector2.RIGHT.rotated(angle)
	wander_timer = direction_change_interval

# Contact is harmless — only killing it (via player bullets) grants the power-up.
func _on_hurtbox_body_entered(_body: Node2D) -> void:
	pass

func die() -> void:
	if player and player.has_method("activate_smg_weapon"):
		player.activate_smg_weapon(spread_duration)
	super.die()
