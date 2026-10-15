extends Node

var camera: Camera2D = null

# Called by your camera's own script on _ready() so Juice knows who to shake.
func register_camera(cam: Camera2D) -> void:
	camera = cam

func screen_shake(amount := 0.3) -> void:
	if camera and camera.has_method("add_trauma"):
		camera.add_trauma(amount)

# duration = how long real-world time the game freezes for.
# time_scale = how slowed-down it is during that freeze (smaller = more frozen).
func hit_stop(duration := 0.04, time_scale := 0.05) -> void:
	Engine.time_scale = time_scale
	# ignore_time_scale=true is essential here — without it, this timer would
	# itself be slowed by the time_scale it's trying to undo, and the freeze
	# would last far longer than intended (or never end).
	var timer := get_tree().create_timer(duration, true, false, true)
	timer.timeout.connect(func(): Engine.time_scale = 1.0)
