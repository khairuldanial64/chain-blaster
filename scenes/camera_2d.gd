extends Camera2D

# ── Tunables ────────────────────────────────────────────────
@export var trauma_power := 2.0       # higher = shake feels calmer at low trauma, snappier at high trauma
@export var decay := 1.5              # how fast trauma drains per second
@export var max_offset := Vector2(24.0, 24.0)
@export var max_roll := 0.05          # radians of camera tilt at full trauma

# ── Mouse lean ──────────────────────────────────────────────
@export var mouse_lean_amount := 150.0   # max pixels the camera shifts toward the mouse
@export var mouse_lean_smoothing := 5.0  # higher = snaps to the mouse faster, lower = floatier

var trauma := 0.0
var lean_offset := Vector2.ZERO

func _ready() -> void:
	if has_node("/root/Juice"):
		get_node("/root/Juice").register_camera(self)

func _process(delta: float) -> void:
	_update_mouse_lean(delta)

	var shake_offset := Vector2.ZERO
	var shake_roll := 0.0

	if trauma > 0.0:
		trauma = max(trauma - decay * delta, 0.0)
		var amount := pow(trauma, trauma_power)
		shake_offset = Vector2(
			randf_range(-1.0, 1.0) * max_offset.x * amount,
			randf_range(-1.0, 1.0) * max_offset.y * amount
		)
		shake_roll = randf_range(-1.0, 1.0) * max_roll * amount

	offset = shake_offset + lean_offset
	rotation = shake_roll

func _update_mouse_lean(delta: float) -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var mouse_pos := get_viewport().get_mouse_position()
	var screen_center := viewport_size / 2.0

	var normalized := Vector2(
		clamp((mouse_pos.x - screen_center.x) / screen_center.x, -1.0, 1.0),
		clamp((mouse_pos.y - screen_center.y) / screen_center.y, -1.0, 1.0)
	)
	var target_lean := normalized * mouse_lean_amount
	lean_offset = lean_offset.lerp(target_lean, clamp(mouse_lean_smoothing * delta, 0.0, 1.0))

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)
