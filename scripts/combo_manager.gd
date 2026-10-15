extends Node
var combo_enabled := true
# ── Tunables ────────────────────────────────────────────────
const KILLS_TO_START_COMBO := 3      # kills needed before timer/multiplier kick in
const BASE_TIMER := 4.0              # seconds given when combo first starts
const TIMER_DECAY_PER_KILL := 0.35   # how much the window shrinks each kill
const MIN_TIMER := 1.2               # floor so it never becomes impossible
const MAX_MULTIPLIER := 10           # optional cap, set high/0 to disable

# ── State ───────────────────────────────────────────────────
var kill_streak: int = 0
var multiplier: int = 1
var combo_active: bool = false
var current_timer_duration: float = 0.0
var time_remaining: float = 0.0

# ── Signals for UI to hook into ────────────────────────────
signal combo_started
signal combo_kill(multiplier: int, time_remaining: float, time_max: float)
signal combo_broken(final_multiplier: int, final_streak: int)
signal multiplier_changed(new_multiplier: int)

func _process(delta: float) -> void:
	if !combo_enabled:
		return
	if combo_active:
		time_remaining -= delta
		if time_remaining <= 0.0:
			break_combo()

func register_kill() -> void:
	
	if !combo_enabled:
		return
	kill_streak += 1

	if kill_streak < KILLS_TO_START_COMBO:
		return

	if not combo_active:
		combo_active = true
		current_timer_duration = BASE_TIMER
		multiplier = 2
		emit_signal("combo_started")
	else:
		multiplier += 1
		if MAX_MULTIPLIER > 0:
			multiplier = min(multiplier, MAX_MULTIPLIER)
		current_timer_duration = max(MIN_TIMER, current_timer_duration - TIMER_DECAY_PER_KILL)

	time_remaining = current_timer_duration
	emit_signal("multiplier_changed", multiplier)
	emit_signal("combo_kill", multiplier, time_remaining, current_timer_duration)

func register_damage_taken() -> void:
	if !combo_enabled:
		return
	if combo_active or kill_streak > 0:
		break_combo()

func break_combo() -> void:
	var final_mult := multiplier
	var final_streak := kill_streak
	combo_active = false
	kill_streak = 0
	multiplier = 1
	time_remaining = 0.0
	emit_signal("combo_broken", final_mult, final_streak)
	emit_signal("multiplier_changed", multiplier)

func get_score_for_kill(base_points: int) -> int:
	if !combo_enabled:
		return base_points
	return base_points * multiplier
