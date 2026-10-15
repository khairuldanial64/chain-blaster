extends CanvasLayer

@export var title_scene_path := "res://scenes/title_scene.tscn"
@export var slide_duration := 0.5
@export var bottom_margin := 40.0

@onready var popup: Control = $Popup
@onready var score_label: Label = $Popup/VBoxContainer/ScoreLabel
@onready var high_score_label: Label = $Popup/VBoxContainer/HighScoreLabel
@onready var restart_button: Button = $Popup/VBoxContainer/RestartButton
@onready var menu_button: Button = $Popup/VBoxContainer/MenuButton

var hidden_y := 0.0
var visible_y := 0.0
var _player_connected := false

func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	call_deferred("_setup_positions")

func _setup_positions() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	popup.position.x = (viewport_size.x - popup.size.x) / 2.0
	visible_y = (viewport_size.y - popup.size.y) / 2.0
	hidden_y = viewport_size.y + 200.0  # fully below the visible screen
	popup.position.y = hidden_y

func _process(_delta: float) -> void:
	if not _player_connected:
		_connect_to_player()

func _connect_to_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	player.player_died.connect(_on_player_died)
	_player_connected = true

func _on_player_died() -> void:
	show_popup()

# Can also be called directly (e.g. from your main scene script) instead of
# relying on the automatic player_died connection above.
func show_popup() -> void:
	if has_node("/root/ScoreManager"):
		var sm := get_node("/root/ScoreManager")
		score_label.text = "Score: %d" % sm.score
		high_score_label.text = "High Score: %d" % sm.high_score

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(popup, "position:y", visible_y, slide_duration)

func hide_popup() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(popup, "position:y", hidden_y, slide_duration * 0.6)

func _on_restart_pressed() -> void:
	$UIButtonSounds.play()
	if has_node("/root/ScoreManager"):
		get_node("/root/ScoreManager").reset_score()
	if has_node("/root/ComboManager"):
		get_node("/root/ComboManager").break_combo()
	Transition.fade_to_scene("res://scenes/main.tscn")
	
func _on_menu_pressed() -> void:
	$UIButtonSounds.play()
	ScoreManager.scoring_enabled = true
	ComboManager.combo_enabled = true
	Transition.fade_to_scene("res://scenes/title_scene.tscn")
