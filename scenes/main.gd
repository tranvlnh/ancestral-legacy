extends Node2D

var screen_size: Vector2i
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	screen_size = get_window().size
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$Player.position.x += 1
	$Camera2D.position.x += 1
	
	if $Camera2D.position.x - $Foreground.position.x > screen_size.x:
		$Foreground.position.x += screen_size.x
	pass
