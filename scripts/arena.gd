extends Node

# Arena is centered on (0, 0). Adjust ARENA_SIZE to match your intended play space —
# this should generally be somewhat larger than one screen so there's room to maneuver.
const ARENA_SIZE := Vector2(2400, 1600)

func get_bounds() -> Rect2:
	return Rect2(-ARENA_SIZE / 2.0, ARENA_SIZE)

# Clamps a position inside the arena, optionally shrinking the usable area by `margin`
# (useful to keep a ship's collision shape from visually clipping into the wall).
func clamp_position(pos: Vector2, margin: float = 0.0) -> Vector2:
	var bounds := get_bounds()
	return Vector2(
		clamp(pos.x, bounds.position.x + margin, bounds.position.x + bounds.size.x - margin),
		clamp(pos.y, bounds.position.y + margin, bounds.position.y + bounds.size.y - margin)
	)

func is_outside_bounds(pos: Vector2, margin: float = 0.0) -> bool:
	var bounds := get_bounds()
	return pos.x < bounds.position.x + margin or pos.x > bounds.position.x + bounds.size.x - margin \
		or pos.y < bounds.position.y + margin or pos.y > bounds.position.y + bounds.size.y - margin

# Picks a random point along the arena's edge, retrying if it lands too close to `avoid_point`.
func random_edge_point(avoid_point: Vector2 = Vector2.INF, min_distance_from_avoid := 300.0, inset := 40.0) -> Vector2:
	var bounds := get_bounds()
	var point := Vector2.ZERO

	for attempt in 8:
		var edge := randi() % 4
		match edge:
			0: point = Vector2(randf_range(bounds.position.x + inset, bounds.position.x + bounds.size.x - inset), bounds.position.y + inset)
			1: point = Vector2(randf_range(bounds.position.x + inset, bounds.position.x + bounds.size.x - inset), bounds.position.y + bounds.size.y - inset)
			2: point = Vector2(bounds.position.x + inset, randf_range(bounds.position.y + inset, bounds.position.y + bounds.size.y - inset))
			3: point = Vector2(bounds.position.x + bounds.size.x - inset, randf_range(bounds.position.y + inset, bounds.position.y + bounds.size.y - inset))

		if avoid_point == Vector2.INF or point.distance_to(avoid_point) >= min_distance_from_avoid:
			return point

	return point  # fall back to last attempt if we never found a "safe" spot
