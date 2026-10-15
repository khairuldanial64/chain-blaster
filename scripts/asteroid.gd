extends CharacterBody2D
class_name Asteroid

# ── Movement ────────────────────────────────────────────────
@export var min_speed := 40.0
@export var max_speed := 120.0
@export var min_spin := -1.5          # rad/sec, negative = counter-clockwise
@export var max_spin := 1.5

# ── Destructible / splitting (classic Asteroids behavior) ────
@export var destructible := true      # if false, bullets pass through / don't kill it
@export var max_health := 1
@export var size_tier := 2            # 2 = large, 1 = medium, 0 = small (won't split further)
@export var split_count := 2          # how many smaller asteroids spawn on death
@export var split_scale := 0.6        # size multiplier applied per tier down
@export var score_value := 50
@export var contact_damage := 1       # passed to player's take_damage()
@export var use_viewport_bounds := false  # true = bounce within the viewport instead of the gameplay Arena (for decorative use, e.g. title screen backgrounds)
@export var death_particles: PackedScene = preload("res://scenes/death_particles.tscn")
@export var score_popup_scene: PackedScene = preload("res://scenes/score_popups.tscn")

var health: int
var spin_speed: float
var move_direction: Vector2

func _ready() -> void:
	add_to_group("asteroids")
	health = max_health
	spin_speed = randf_range(min_spin, max_spin)

	var angle := randf_range(0.0, TAU)
	move_direction = Vector2.RIGHT.rotated(angle)
	velocity = move_direction * randf_range(min_speed, max_speed)

	scale = Vector2.ONE * (0.5 + 0.25 * size_tier)  # smaller tiers render smaller
		
	var hurtbox := get_node_or_null("Hurtbox")
	if hurtbox:
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	else:
		push_warning("Asteroid: no child node named 'Hurtbox' found — contact damage won't work.")

func _physics_process(delta: float) -> void:
	rotation += spin_speed * delta
	move_and_slide()
	_bounce_off_walls()

func _bounce_off_walls() -> void:
	var bounds: Rect2
	if use_viewport_bounds:
		bounds = Rect2(Vector2.ZERO, get_viewport_rect().size)
	elif has_node("/root/Arena"):
		bounds = get_node("/root/Arena").get_bounds()
	else:
		return
 
	if global_position.x < bounds.position.x or global_position.x > bounds.position.x + bounds.size.x:
		velocity.x = -velocity.x
	if global_position.y < bounds.position.y or global_position.y > bounds.position.y + bounds.size.y:
		velocity.y = -velocity.y
 
	global_position.x = clamp(global_position.x, bounds.position.x, bounds.position.x + bounds.size.x)
	global_position.y = clamp(global_position.y, bounds.position.y, bounds.position.y + bounds.size.y)
 

func take_damage(amount: int) -> void:
	if not destructible:
		return
	health -= amount
	if health <= 0:
		call_deferred("_break_apart")

func _break_apart() -> void:
	
	var sound_player := get_node_or_null("DeathSound")
	if sound_player:
		remove_child(sound_player)
		get_tree().current_scene.add_child(sound_player)
		sound_player.global_position = global_position
		sound_player.play()
		sound_player.finished.connect(sound_player.queue_free)
		
	if has_node("/root/ScoreManager") and has_node("/root/ComboManager"):
		var sm := get_node("/root/ScoreManager")
		var combo := get_node("/root/ComboManager")
		sm.add_score(combo.get_score_for_kill(score_value))
		combo.register_kill()
		_spawn_score_popup(combo.get_score_for_kill(score_value))
		
	if has_node("/root/Juice"):
		var juice := get_node("/root/Juice")
		juice.screen_shake(0.3)
		juice.hit_stop(0.04, 0.05)
		
	if death_particles:
		var fx := death_particles.instantiate()
		fx.color = Color("3d3d3dff")
		fx.global_position = global_position
		get_tree().current_scene.add_child(fx)

	if size_tier > 0:
		for i in split_count:
			var piece: Asteroid = duplicate() as Asteroid
			get_parent().add_child(piece)
			piece.global_position = global_position
			piece.size_tier = size_tier - 1
			piece.max_health = max(1, int(max_health * split_scale))
			
			# ── FORCE THE FRAME UPDATE ON THE DUPLICATED PIECE ──
			# We reach into the piece's child node directly to bypass the onready bug
			var piece_sprite = piece.get_node_or_null("Sprite2D")
			if piece_sprite:
				piece_sprite.frame = 2 - piece.size_tier
			# ───────────────────────────────────────────────────

	queue_free()


func _on_hurtbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(contact_damage)
		if has_node("/root/ComboManager"):
			get_node("/root/ComboManager").register_damage_taken()

func _spawn_score_popup(points: int) -> void:
	if score_popup_scene == null:
		return
	var popup := score_popup_scene.instantiate()
	popup.global_position = global_position
	get_tree().current_scene.add_child(popup)
	if popup.has_method("set_value"):
		popup.set_value(points)
