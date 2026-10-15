extends Node2D

@export var border_color := Color("990000ff")  # values above 1.0 catch WorldEnvironment glow
@export var border_width := 6.0
@export var pulse_speed := 2.0
@export var pulse_amount := 0.3

var line: Line2D
var base_color: Color

func _ready() -> void:
	if not has_node("/root/Arena"):
		push_warning("ArenaBorder: Arena autoload not found.")
		return

	var arena := get_node("/root/Arena")
	var bounds: Rect2 = arena.get_bounds()

	line = Line2D.new()
	line.width = border_width
	line.default_color = border_color
	line.closed = true
	line.add_point(bounds.position)
	line.add_point(Vector2(bounds.position.x + bounds.size.x, bounds.position.y))
	line.add_point(bounds.position + bounds.size)
	line.add_point(Vector2(bounds.position.x, bounds.position.y + bounds.size.y))
	add_child(line)

	base_color = border_color

func _process(_delta: float) -> void:
	if line == null:
		return
	var pulse := 1.0 + sin(Time.get_ticks_msec() / 1000.0 * pulse_speed) * pulse_amount
	line.default_color = Color(base_color.r * pulse, base_color.g * pulse, base_color.b * pulse, base_color.a)
