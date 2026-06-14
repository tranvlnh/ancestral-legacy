extends Area2D

signal collected(points: int)

const POINTS: int = 50

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		collected.emit(POINTS)
		queue_free()
