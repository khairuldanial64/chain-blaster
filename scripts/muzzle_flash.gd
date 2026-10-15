extends CPUParticles2D

@export var flash_color := Color(1.0, 1.0, 0.4)
@export var particle_count := 8
@export var particle_lifetime := 0.12
@export var particle_speed := 300.0
@export var particle_scale := 3.0
@export var cone_spread := 20.0  # degrees — how wide the spark cone is

func _ready() -> void:
	one_shot = true
	amount = particle_count
	lifetime = particle_lifetime
	explosiveness = 1.0

	emission_shape = CPUParticles2D.EMISSION_SHAPE_POINT
	direction = Vector2.RIGHT  # local +X — combine with node rotation to aim the cone
	spread = cone_spread
	initial_velocity_min = particle_speed * 0.6
	initial_velocity_max = particle_speed

	scale_amount_min = particle_scale * 0.5
	scale_amount_max = particle_scale

	gravity = Vector2.ZERO
	damping_min = 200.0
	damping_max = 400.0

	color = flash_color

	restart()
	await get_tree().create_timer(particle_lifetime + 0.1, true, false, true).timeout
	queue_free()
