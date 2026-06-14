extends Area2D

signal player_hit

var _initial_y: float
func _ready() -> void:
	_initial_y = position.y
	body_entered.connect(_on_body_entered)
	
func _process(delta: float) -> void:
	position.y = _initial_y + sin(Time.get_ticks_msec() * 0.004) * 7.0

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		player_hit.emit()
