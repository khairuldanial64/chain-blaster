extends Node2D

@export var rise_distance := 60.0
@export var duration := 0.8

@onready var label: Label = $Label

func _ready() -> void:
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - rise_distance, duration)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(label, "modulate:a", 0.0, duration).set_delay(duration * 0.3)
	tween.tween_callback(queue_free)

func set_value(points: int, color := Color.WHITE) -> void:
	label.text = "+%d" % points
	label.modulate = color
