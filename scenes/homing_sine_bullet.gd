extends Area2D

@export var speed := 260.0
@export var turn_rate := 2.0        # radians/sec — how aggressively it curves toward the player
@export var wave_frequency := 3.0   # higher = tighter/faster wiggles
@export var wave_amplitude := 40.0  # how wide the sideways weave is
@export var damage := 1
@export var lifetime := 6.0
@export var health := 1

var forward_direction := Vector2.RIGHT  # set externally at spawn (boss sets this toward the player)
var distance_traveled := 0.0
var previous_wave_offset := 0.0
var player: Node2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player:
		var desired := (player.global_position - global_position).normalized()
		var angle_diff := wrapf(desired.angle() - forward_direction.angle(), -PI, PI)
		var max_turn := turn_rate * delta
		angle_diff = clamp(angle_diff, -max_turn, max_turn)
		forward_direction = forward_direction.rotated(angle_diff)

	distance_traveled += speed * delta
	var wave_offset := sin(distance_traveled * wave_frequency * 0.01) * wave_amplitude
	var lateral_direction := forward_direction.rotated(PI / 2)
	var lateral_delta := wave_offset - previous_wave_offset
	previous_wave_offset = wave_offset

	position += forward_direction * speed * delta + lateral_direction * lateral_delta
	rotation = forward_direction.angle()

func _on_area_entered(area: Area2D) -> void:
	if area.has_method("take_damage"):
		area.take_damage(damage)
	call_deferred("queue_free")

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	call_deferred("queue_free")
	
func take_damage(amount := 0) -> void:
	health -= amount
	if health <= 0:
		call_deferred("queue_free")
