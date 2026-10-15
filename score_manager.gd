extends Node

signal score_changed(new_score: int)
signal high_score_changed(new_high_score: int)
var scoring_enabled := true
var score: int = 0
var high_score: int = 0

const SAVE_PATH := "user://highscore.save"

func _ready() -> void:
	_load_high_score()

func add_score(amount: int) -> void:
	if !scoring_enabled:
		return 
	score += amount
	emit_signal("score_changed", score)
	if score > high_score:
		high_score = score
		emit_signal("high_score_changed", high_score)

func reset_score() -> void:
	score = 0
	emit_signal("score_changed", score)

func save_high_score() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_var(high_score)

func _load_high_score() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			high_score = file.get_var()
			
func reset_high_score() -> void:
	high_score = 0
	emit_signal("high_score_changed", high_score)
	save_high_score()
