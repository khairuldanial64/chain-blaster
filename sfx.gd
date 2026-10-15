extends Node

func play_sound(stream: AudioStream, pos: Vector2, volume_db := 0.0, pitch_variation := 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	if pitch_variation > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.global_position = pos
	get_tree().current_scene.add_child(player)
	player.play()
	player.finished.connect(player.queue_free)
