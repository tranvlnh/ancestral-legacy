extends Node2D

const OBSTACLE_SCENE: PackedScene = preload("res://entities/obstacle/obstacle.tscn")
const BASE_SPEED: float = 150.0
const SPEED_SCALE_RATE: float = 0.8
const MAX_SPEED: float = 400.0
const SPAWN_DISTANCE_MIN: float = 200.0
const SPAWN_DISTANCE_MAX: float = 350.0
const SPAWN_BUFFER_X: float = 80.0
const CLEANUP_BUFFER_X: float = 80.0
const OBSTACLE_Y: float = 134.0

var screen_size: Vector2
var distance_travelled: float = 0.0
var next_obstacle_spawn_distance: float = SPAWN_DISTANCE_MIN
var spawned_obstacles: Array[Node2D] = []
var game_over: bool = false
var score: int = 0

func _ready() -> void:
	screen_size = get_viewport_rect().size
	$Player.died.connect(_on_player_died)
	$UI.restart_requested.connect(_on_restart_requested)

func _process(delta: float) -> void:
	if game_over:
		return

	var current_speed := BASE_SPEED + (SPEED_SCALE_RATE * (distance_travelled / 100.0))
	current_speed = min(current_speed, MAX_SPEED)
	var movement := current_speed * delta

	$Player.position.x += movement
	$Camera2D.position.x += movement
	distance_travelled += movement
	score = int(distance_travelled / 10.0)
	$UI.update_score(score)

	_spawn_obstacles()
	_cleanup_obstacles()

	if $Camera2D.position.x - $Foreground.position.x > screen_size.x:
		$Foreground.position.x += screen_size.x

func _spawn_obstacles() -> void:
	while distance_travelled >= next_obstacle_spawn_distance:
		var obstacle := OBSTACLE_SCENE.instantiate() as Node2D
		obstacle.position = Vector2($Camera2D.position.x + screen_size.x + SPAWN_BUFFER_X, OBSTACLE_Y)
		obstacle.player_hit.connect(_on_obstacle_hit)
		add_child(obstacle)
		spawned_obstacles.append(obstacle)
		var spawn_gap := randf_range(SPAWN_DISTANCE_MIN, SPAWN_DISTANCE_MAX)
		next_obstacle_spawn_distance += spawn_gap
   
func _cleanup_obstacles() -> void:
	for i in range(spawned_obstacles.size() - 1, -1, -1):
		var obstacle := spawned_obstacles[i]
		if obstacle.position.x < $Camera2D.position.x - CLEANUP_BUFFER_X:
			spawned_obstacles.remove_at(i)
			obstacle.queue_free()

func _on_obstacle_hit() -> void:
	$Player.die()
	$AudioManager.play_hit()

func _on_player_died() -> void:
	game_over = true
	$UI.show_game_over(score)

func _on_restart_requested() -> void:
	get_tree().reload_current_scene()
