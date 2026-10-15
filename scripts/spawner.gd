extends Node2D

# ── Enemy pool (fill these three arrays in the Inspector, same index = same entry) ──
@export var enemy_scenes: Array[PackedScene] = []
@export var enemy_weights: Array[float] = []       # relative spawn chance, doesn't need to sum to 1
@export var enemy_unlock_times: Array[float] = []  # seconds since start before this type can appear

# ── Asteroid pool ───────────────────────────────────────────
@export var asteroid_scene: PackedScene
@export var asteroid_interval := 3.0

# ── Enemy spawn pacing / difficulty ramp ───────────────────
@export var base_spawn_interval := 2.5    # seconds between enemy spawns at the start
@export var min_spawn_interval := 0.6     # fastest it will ever get
@export var difficulty_ramp_time := 120.0 # seconds to go from base to min interval

# ── Spawn positioning ───────────────────────────────────────
@export var min_distance_from_player := 350.0  # don't spawn right on top of the player
@export var spawn_inset := 100.0  # keep spawn points this far inside the boundary — should be >= your largest enemy/asteroid's collision radius

var elapsed_time := 0.0
var enemy_spawn_timer := 0.0
var asteroid_spawn_timer := 0.0
var player: Node2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	enemy_spawn_timer = base_spawn_interval
	asteroid_spawn_timer = asteroid_interval

func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	elapsed_time += delta

	enemy_spawn_timer -= delta
	if enemy_spawn_timer <= 0.0:
		_spawn_enemy()
		enemy_spawn_timer = _current_spawn_interval()

	asteroid_spawn_timer -= delta
	if asteroid_spawn_timer <= 0.0:
		_spawn_asteroid()
		asteroid_spawn_timer = asteroid_interval

func _current_spawn_interval() -> float:
	var t = clamp(elapsed_time / difficulty_ramp_time, 0.0, 1.0)
	return lerp(base_spawn_interval, min_spawn_interval, t)

func _spawn_enemy() -> void:
	var scene := _pick_weighted_enemy()
	if scene == null:
		return

	var enemy := scene.instantiate()
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _get_offscreen_spawn_point()

func _pick_weighted_enemy() -> PackedScene:
	var available: Array[int] = []
	for i in enemy_scenes.size():
		var unlock_time := 0.0
		if i < enemy_unlock_times.size():
			unlock_time = enemy_unlock_times[i]
		if elapsed_time >= unlock_time:
			available.append(i)

	if available.is_empty():
		return null

	var total_weight := 0.0
	for i in available:
		var w := 1.0
		if i < enemy_weights.size():
			w = enemy_weights[i]
		total_weight += w

	var roll := randf_range(0.0, total_weight)
	var cumulative := 0.0
	for i in available:
		var w := 1.0
		if i < enemy_weights.size():
			w = enemy_weights[i]
		cumulative += w
		if roll <= cumulative:
			return enemy_scenes[i]

	return enemy_scenes[available.back()]

func _spawn_asteroid() -> void:
	if asteroid_scene == null:
		return
	var asteroid := asteroid_scene.instantiate()
	get_tree().current_scene.add_child(asteroid)
	asteroid.global_position = _get_offscreen_spawn_point()

func _get_offscreen_spawn_point() -> Vector2:
	if not has_node("/root/Arena"):
		push_warning("Spawner: Arena autoload not found — falling back to origin.")
		return Vector2.ZERO
	var arena := get_node("/root/Arena")
	var player_pos := player.global_position if player else Vector2.ZERO
	return arena.random_edge_point(player_pos, min_distance_from_player, spawn_inset)

func reset() -> void:
	elapsed_time = 0.0
	enemy_spawn_timer = base_spawn_interval
	asteroid_spawn_timer = asteroid_interval
	
func stop_spawning():
	enemy_spawn_timer = 1000000
