extends ProgressBar

# --- Customization Parameters ---
@export var pulse_speed := 2.0      # How fast the bar breathes (higher = faster)
@export var scale_intensity := 0.02  # How much it expands (0.03 = 3% size change)
@export var glow_intensity := 0.15   # How much the brightness fluctuates

var base_scale := Vector2.ONE

func _ready() -> void:
	visible = false
		# 1. Store the starting design scale
	base_scale = scale

func _process(_delta: float) -> void:
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		visible = false
		return
		
	var player = players[0]
	
	# If the weapon type is anything other than DEFAULT (0), show the progress bar
	if player.current_weapon != 0: 
		visible = true
		max_value = player.powerup_max_duration
		value = player.powerup_timer
		
		# Optional UX: Dynamic color swapping depending on what powerup is active!
		if player.current_weapon == 1: # SPREAD
			modulate = Color("ff9200ff") # Cyan
		elif player.current_weapon == 2: # SMG
			modulate = Color("ba01afff") # Synthwave Pink
	else:
		visible = false
		
	bar_pulsing()

func bar_pulsing():
	# Only pulse if the bar is actively visible on the screen
	if is_visible_in_tree():
		# Create a continuous looping wave between -1.0 and 1.0 using engine TIME
		var wave = sin(Time.get_ticks_msec() * 0.001 * pulse_speed)
		# Calculate the current fill percentage (0.0 to 1.0)
		var fill_ratio = value / max_value
		
		# If the bar drops below 25%, double the speed and intensity!
		if fill_ratio < 0.25:
			pulse_speed = 12.0       # Rapid hyper-pulse
			scale_intensity = 0.04   # Exaggerated shake size
			
		else:
			# Reset back to calm defaults when full
			pulse_speed = 4.0
			scale_intensity = 0.03
			# Keep your original powerup theme colors here (e.g., Cyan or Pink)

		# 3. BREATHING SCALE ANIMATION
		# Scale expands when wave is positive, shrinks when negative
		scale = base_scale + Vector2.ONE * (wave * scale_intensity)
		
		# 4. GLOWING BRIGHTNESS ANIMATION
		# We use RAW/HDR color values to drive a neon brightness fluctuation
		# (Works beautifully if you have WorldEnvironment Glow enabled!)
		var energy_multiplier = 1.0 + (wave * glow_intensity)
		
		# Gently brighten/dim the self_modulate layer
		self_modulate.v = energy_multiplier 
	else:
		# Reset back to perfect defaults if the bar disappears
		scale = base_scale
		self_modulate.v = 1.0
