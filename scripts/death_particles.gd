extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Start emitting immediately when spawned
	$CPUParticles2D.emitting = true
	# Automatically destroy this node once the animation completes
	$CPUParticles2D.finished.connect(queue_free)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
