extends Area2D

@export var lifetime := 2.0
@export var damage := 1
@export var health := 1

var velocity := Vector2.ZERO

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(queue_free)
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += velocity * delta

func set_velocity(v: Vector2) -> void:
	velocity = v

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
