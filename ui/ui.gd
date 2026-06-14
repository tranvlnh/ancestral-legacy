extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var game_over_panel: Panel = $GameOverPanel
@onready var final_score_label: Label = $GameOverPanel/VBoxContainer/FinalScoreLabel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton

signal restart_requested

func _ready() -> void:
	game_over_panel.hide()
	restart_button.pressed.connect(_on_restart_pressed)

func update_score(score: int) -> void:
	score_label.text = "Score: %d" % score

func show_game_over(final_score: int) -> void:
	final_score_label.text = "Final Score: %d" % final_score
	game_over_panel.show()

func _on_restart_pressed() -> void:
	restart_requested.emit()
