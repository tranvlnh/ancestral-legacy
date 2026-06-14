extends Area2D

signal collected(points: int)

const POINTS: int = 100

var _initial_y: float

func _ready() -> void:
	_initial_y = position.y
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	# Floating bob animation — dễ thấy hơn, thu hút attention
	position.y = _initial_y + sin(Time.get_ticks_msec() * 0.004) * 6.0

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		collected.emit(POINTS)
		queue_free()
