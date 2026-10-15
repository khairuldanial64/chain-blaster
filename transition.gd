extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	layer = 100  # render on top of everything
	color_rect.color = Color(0, 0, 0, 0)  # start fully transparent
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # don't block clicks when invisible

func fade_to_scene(scene_path: String, duration: float = 0.4) -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # block input during fade
	
	var tween = create_tween()
	tween.tween_property(color_rect, "color:a", 1.0, duration)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))
	tween.tween_property(color_rect, "color:a", 0.0, duration)
	tween.tween_callback(func(): color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE)
	
