extends Node2D

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var multiplier_label: Label = $CanvasLayer/MultiplierLabel
@onready var combo_bar = $CanvasLayer/ComboBar
@onready var health_bar = $CanvasLayer/HealthBar
@onready var boss_bar = $CanvasLayer/BossBar

@onready var player = $Player
@onready var ui = $CanvasLayer
@onready var death_screen = $DeathScreen
@onready var boss = $Boss

@onready var color_rect: ColorRect = $Bg/ColorRect
@onready var camera: Camera2D = $Player/Camera2D # Change to your actual Camera path

func _ready() -> void:
	$StartSound.play()
	if has_node("/root/ScoreManager"):
		ScoreManager.scoring_enabled = false

	if has_node("/root/ComboManager"):
		ComboManager.combo_enabled = false
		
	if player:
		# Connect the player's health_changed signal to the UI's update function
		player.health_changed.connect(update_health_ui)
		player.player_died.connect(_on_player_died)
		
	if boss:
		boss.health_changed.connect(update_health_boss_ui)
		boss.died.connect(_on_boss_died)
		
	combo_bar.visible = false
	multiplier_label.visible = false

func _on_score_changed(new_score: int) -> void:
	score_label.text = "Score: %d" % new_score
	_punch_score_label()

func _on_multiplier_changed(new_multiplier: int) -> void:
	multiplier_label.text = "x%d" % new_multiplier

func _on_combo_started() -> void:
	combo_bar.visible = false
	multiplier_label.visible = false

func _on_combo_kill(_multiplier: int, time_remaining: float, time_max: float) -> void:
	combo_bar.visible = false
	combo_bar.max_value = time_max
	combo_bar.value = time_remaining
	_punch_multiplier_label()
	$MultiplierSound.play()
	
func _punch_score_label() -> void:
	score_label.pivot_offset = score_label.size / 2.0
	score_label.scale = Vector2(1.1, 1.1)
	var tween := create_tween()
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _punch_multiplier_label() -> void:
	multiplier_label.pivot_offset = multiplier_label.size / 2.0
	multiplier_label.scale = Vector2(1.5, 1.5)
	var tween := create_tween()
	tween.tween_property(multiplier_label, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
func _punch_health_bar() -> void:
	health_bar.pivot_offset = health_bar.size / 2.0
	health_bar.scale = Vector2(1.5, 1.5)
	var tween := create_tween()
	tween.tween_property(health_bar, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
func _punch_boss_bar() -> void:
	boss_bar.pivot_offset = boss_bar.size / 2.0
	boss_bar.scale = Vector2(1.1, 1.1)
	var tween := create_tween()
	tween.tween_property(boss_bar, "scale", Vector2.ONE, 0.25)\
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		
func _on_combo_broken(_final_multiplier: int, _final_streak: int) -> void:
	combo_bar.visible = false
	multiplier_label.visible = false
	$ComboBrokenSound.play()

func _process(_delta: float) -> void:
	# Keep the bar draining smoothly between kill events rather than only
	# snapping to a new value each time combo_kill fires.
	if has_node("/root/ComboManager"):
		var combo := get_node("/root/ComboManager")
		if combo.combo_active:
			combo_bar.value = combo.time_remaining
			
	if camera and color_rect:
		# 1. Fetch the absolute world center of the camera
		var cam_pos = camera.get_screen_center_position()
		
		# 2. Invert the Y-axis because screen coordinates go down, 
		# while Godot 2D world coordinates go up/down differently.
		var shader_offset = Vector2(cam_pos.x, -cam_pos.y)
		
		# 3. Inject this data straight into the shader material parameters
		color_rect.material.set_shader_parameter("camera_offset", shader_offset)

func update_health_ui(current: int, max_hp: int) -> void:
	# Update the bar's max value and current value
	health_bar.max_value = max_hp
	health_bar.value = current
	_punch_health_bar()

func _on_player_died() -> void:
	$VictoryScreen.hide()
	$BgMusic.stop()
	$DieSound.play()
	death_screen.show_popup()
	$DeathScreen/Popup/BlurOverlay.show()
	$Spawner.stop_spawning()
	
func update_health_boss_ui(health, max_health):
	boss_bar.max_value = max_health
	boss_bar.value = health
	_punch_boss_bar()
	
func _on_boss_died(_boss):
	player.disable_combat()
	$DeathScreen.hide()
	$BgMusic.stop()
	$VictorySound.play()
	$VictoryScreen.show_popup()
	$VictoryScreen/Popup/BlurOverlay.show()
	$Spawner.stop_spawning()
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if "is_frozen" in enemy:
			enemy.is_frozen = true
