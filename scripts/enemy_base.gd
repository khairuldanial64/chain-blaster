extends CharacterBody2D
class_name EnemyBase

# ── Tunables (override per-variant in the Inspector) ──────────
@export var max_health := 3
@export var score_value := 100
@export var contact_damage := 1        # damage dealt to player on collision
@export var arena_bounds_margin := 30.0  # increase for enemies with a larger sprite/collision radius
@export var death_particles: PackedScene = preload("res://scenes/death_particles.tscn")  # optional, assign an explosion scene
@export var score_popup_scene: PackedScene = preload("res://scenes/score_popups.tscn")
var health: int
var player: Node2D = null

var is_frozen := false
var _connected_to_player_died := false

signal died(enemy: EnemyBase)
signal health_changed(current_health: int, max_health: int)

func _ready() -> void:
	health = max_health
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")

	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	else:
		push_warning("EnemyBase: no child node named 'Hurtbox' found — contact damage won't work.")

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
		
	if not _connected_to_player_died and player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
		_connected_to_player_died = true
 
	if is_frozen:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	_update_behavior(delta)
	move_and_slide()
	_enforce_arena_bounds()

func _on_player_died() -> void:
	is_frozen = true

func _enforce_arena_bounds() -> void:
	if not has_node("/root/Arena"):
		return
	var arena := get_node("/root/Arena")
	var bounds: Rect2 = arena.get_bounds()

	if global_position.x < bounds.position.x or global_position.x > bounds.position.x + bounds.size.x:
		velocity.x = -velocity.x * 0.3  # soft bounce back inward rather than a hard stop
	if global_position.y < bounds.position.y or global_position.y > bounds.position.y + bounds.size.y:
		velocity.y = -velocity.y * 0.3

	global_position = arena.clamp_position(global_position, arena_bounds_margin)

# Override this in each variant script (stationary/dasher/mobile shooter)
func _update_behavior(_delta: float) -> void:
	pass

func take_damage(amount: int) -> void:
	if has_node("/root/Juice"):
		var juice := get_node("/root/Juice")
		juice.screen_shake(0.3)
		juice.hit_stop(0.04, 0.05)
	
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		die()

func die() -> void:
	emit_signal("died", self)
	
	var sound_player := get_node_or_null("DeathSound")
	if sound_player:
		remove_child(sound_player)
		get_tree().current_scene.add_child(sound_player)
		sound_player.global_position = global_position
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)
	
	if has_node("/root/Juice"):
		var juice := get_node("/root/Juice")
		juice.screen_shake(0.3)
		juice.hit_stop(0.04, 0.05)

	if has_node("/root/ScoreManager"):
		var sm := get_node("/root/ScoreManager")
		if sm.has_method("add_score") and has_node("/root/ComboManager"):
			var combo := get_node("/root/ComboManager")
			sm.add_score(combo.get_score_for_kill(score_value))
			combo.register_kill()
			_spawn_score_popup(combo.get_score_for_kill(score_value))

	if death_particles:
		var fx := death_particles.instantiate()
		fx.global_position = global_position
		get_tree().current_scene.add_child(fx)
	else:
		push_warning("EnemyBase: death_particles not assigned — no explosion will play.")
	
	call_deferred("queue_free")

func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
		if has_node("/root/ComboManager"):
			get_node("/root/ComboManager").register_damage_taken()

func direction_to_player() -> Vector2:
	if player == null:
		return Vector2.ZERO
	return (player.global_position - global_position).normalized()

func distance_to_player() -> float:
	if player == null:
		return INF
	return global_position.distance_to(player.global_position)

func _spawn_score_popup(points: int) -> void:
	if score_popup_scene == null:
		return
	var popup := score_popup_scene.instantiate()
	popup.global_position = global_position
	get_tree().current_scene.add_child(popup)
	if popup.has_method("set_value"):
		popup.set_value(points)
