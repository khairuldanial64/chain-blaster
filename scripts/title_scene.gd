extends Control

@export var background_asteroid_scene: PackedScene   # assign your Asteroid.tscn
@export var background_asteroid_count := 7
@export var main_scene_path := "res://scenes/main.tscn"      # update to match your actual main scene path

@onready var background_sim: Node2D = $BackgroundSim
@onready var high_score_label: Label = $HighscoreLabel
@onready var play_button: Button = $PlayButton


@export var boss_scene_path := "res://scenes/boss_arena.tscn" # update to match your actual boss arena scene path
 
@export var score_threshold_normal := 300000
@export var score_threshold_playtester := 5000
 
var playtester_mode := false
@onready var boss_button: Button = $BossButton
@onready var playtester_button: Button = $PlaytesterButton
@onready var playtester_confirm_dialog: ConfirmationDialog = $PlaytesterConfirmDialog

func _ready() -> void:
	$TitlePushSound.play()
	play_button.pressed.connect(_on_play_pressed)
	
	boss_button.pressed.connect(_on_boss_pressed)
	playtester_button.pressed.connect(_on_playtester_button_pressed)
	$ConfirmationDialog.dialog_text = "This will reset your High Score, do you wish to continue?"
 
	playtester_confirm_dialog.dialog_text = "This unlocks the The Vault at only %s points instead of %s.\n\nThis is meant ONLY for judges/playtesters to evaluate the boss fight without playing a full run so please don't use it for normal play.\n\nContinue? P.S" % [_format_number(score_threshold_playtester), _format_number(score_threshold_normal)]
	playtester_confirm_dialog.confirmed.connect(_on_playtester_confirmed)
	
	_display_high_score()
	_populate_background()
	_update_boss_button_state()
	
func _update_boss_button_state() -> void:
	var threshold := score_threshold_playtester if playtester_mode else score_threshold_normal
	var current_high_score := 0
	if has_node("/root/ScoreManager"):
		current_high_score = get_node("/root/ScoreManager").high_score
 
	var unlocked := current_high_score >= threshold
	boss_button.disabled = not unlocked
	boss_button.text = "The Vault" if unlocked else "%s pts" % _format_number(threshold)
 
func _format_number(n: int) -> String:
	var s := str(n)
	var result := ""
	var count := 0
	for i in range(s.length() - 1, -1, -1):
		result = s[i] + result
		count += 1
		if count % 3 == 0 and i != 0:
			result = "," + result
	return result

func _display_high_score() -> void:
	if has_node("/root/ScoreManager"):
		var sm := get_node("/root/ScoreManager")
		high_score_label.text = "High Score: %d" % sm.high_score
	else:
		high_score_label.text = "High Score: 0"

func _populate_background() -> void:
	if background_asteroid_scene == null:
		push_warning("TitleScreen: no background_asteroid_scene assigned in the Inspector!")
		return

	var viewport_size := get_viewport_rect().size

	for i in background_asteroid_count:
		var asteroid := background_asteroid_scene.instantiate() as CharacterBody2D
		background_sim.add_child(asteroid)

		# Purely decorative — don't want it splitting into pieces or scoring points.
		if "destructible" in asteroid:
			asteroid.destructible = false
		# Bounce within the visible screen instead of the gameplay Arena's coordinate space.
		if "use_viewport_bounds" in asteroid:
			asteroid.use_viewport_bounds = true

		asteroid.global_position = Vector2(
			randf_range(0.0, viewport_size.x),
			randf_range(0.0, viewport_size.y)
		)
		
		asteroid.global_scale = Vector2(1,1) * randf_range(0.5, 3.5)

func _on_play_pressed() -> void:
	if has_node("/root/ScoreManager"):
		get_node("/root/ScoreManager").reset_score()
	if has_node("/root/ComboManager"):
		get_node("/root/ComboManager").break_combo()
	$PlaySound.play()
	await $PlaySound.finished
	Transition.fade_to_scene("res://scenes/main.tscn")
	
func _process(delta: float) -> void:
	$BackgroundSim/Ship.position += Vector2(-1,-1) * delta * 6
	$BackgroundSim/Sprite2D2.position += Vector2(-1,-1) * delta * 5
	$BackgroundSim/Sprite2D3.position += Vector2(-1,-1) * delta * 5
	$BackgroundSim/Sprite2D4.position += Vector2(-1,-1) * delta * 5


func _on_timer_timeout() -> void:
	$TitlePushSound.play()


func _on_timer_2_timeout() -> void:
	$ReadySound.play()


func _on_play_button_mouse_entered() -> void:
	# Create a clean, responsive snap up effect
	var tween = create_tween()
	
	# TRANS_BACK + EASE_OUT gives it a tiny, subtle overshoot bounce 
	# that feels premium and responsive to user input.
	tween.tween_property($PlayButton, "scale", Vector2.ONE * 1.2, 0.5)\
		.set_trans(Tween.TRANS_BACK)\
		.set_ease(Tween.EASE_OUT)
		
func _on_play_button_mouse_exited() -> void:
	# Return back to default scale smoothly
	var tween = create_tween()
	
	# TRANS_QUAD gives a smooth decelerating return to 1.0 scale
	tween.tween_property($PlayButton, "scale", Vector2.ONE, 0.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
		
func _on_boss_pressed() -> void:
	Transition.fade_to_scene(boss_scene_path)
 
func _on_playtester_button_pressed() -> void:
	playtester_confirm_dialog.popup_centered()
 
func _on_playtester_confirmed() -> void:
	playtester_mode = true
	_update_boss_button_state()


func _on_reset_score_button_pressed() -> void:
	$ConfirmationDialog.popup_centered()

func _on_confirmation_dialog_confirmed() -> void:
	ScoreManager.reset_high_score()
