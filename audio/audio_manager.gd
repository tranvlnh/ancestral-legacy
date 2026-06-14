extends Node

@onready var jump_sound: AudioStreamPlayer = $JumpSound
@onready var hit_sound: AudioStreamPlayer = $HitSound
@onready var score_sound: AudioStreamPlayer = $ScoreSound

func play_jump() -> void:
	if jump_sound:
		jump_sound.play()

func play_hit() -> void:
	if hit_sound:
		hit_sound.play()

func play_score() -> void:
	if score_sound:
		score_sound.play()
