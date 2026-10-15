extends CPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	one_shot = true
	restart()  # forces a clean burst — just having one_shot+emitting pre-checked in the
			   # editor doesn't reliably trigger it, since Godot needs to see an actual
			   # false→true transition (or an explicit restart) to fire correctly.
 
	await get_tree().create_timer(lifetime + 0.1, true, false, true).timeout
	queue_free()
