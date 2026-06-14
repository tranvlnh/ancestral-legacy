extends Node2D

const THORN_SCENE: PackedScene = preload("res://entities/obstacle/thorn.tscn")
const ENEMY_SCENE: PackedScene = preload("res://entities/obstacle/enemy.tscn")
const COFFEE_SCENE: PackedScene = preload("res://entities/collectible/coffee.tscn")

# Game speed constants
const BASE_SPEED: float = 150.0
const SPEED_SCALE_RATE: float = 0.8
const MAX_SPEED: float = 400.0

# Physics constants from PlayerStats
const JUMP_VELOCITY: float = 380.0
const GRAVITY: float = 980.0

# Calculated from physics: time = 2 * (jump_velocity / gravity)
const JUMP_DURATION: float = 0.776  # seconds in air

# Spawn algorithm constants
const MIN_SAFETY_FACTOR: float = 1.8  # Khoảng cách tối thiểu = 1.8x quãng nhảy
const MAX_SAFETY_FACTOR: float = 2.5  # Khoảng cách tối đa = 2.5x quãng nhảy
const DIFFICULTY_CURVE: float = 0.0015  # Tốc độ giảm độ khó

const SPAWN_BUFFER_X: float = 80.0
const CLEANUP_BUFFER_X: float = 80.0
const THORN_Y: float = 144.0
const ENEMY_Y: float = 80.0
const COFFEE_Y: float = 110.0
const COFFEE_SPAWN_CHANCE: float = 0.3  # 30% cơ hội spawn coffee

var screen_size: Vector2
var distance_travelled: float = 0.0
var next_obstacle_spawn_distance: float = 0.0
var next_coffee_spawn_distance: float = 300.0
var spawned_obstacles: Array[Node2D] = []
var spawned_collectibles: Array[Node2D] = []
var game_over: bool = false
var score: int = 0
var current_speed: float = BASE_SPEED

func _ready() -> void:
	screen_size = get_viewport_rect().size
	$Player.died.connect(_on_player_died)
	$UI.restart_requested.connect(_on_restart_requested)

func _process(delta: float) -> void:
	if game_over:
		return

	current_speed = BASE_SPEED + (SPEED_SCALE_RATE * (distance_travelled / 100.0))
	current_speed = min(current_speed, MAX_SPEED)
	var movement := current_speed * delta

	$Player.position.x += movement
	$Camera2D.position.x += movement
	distance_travelled += movement
	score = int(distance_travelled / 10.0)
	$UI.update_score(score)

	_spawn_obstacles()
	_spawn_coffee()
	_cleanup_obstacles()
	_cleanup_collectibles()

	if $Camera2D.position.x - $Foreground.position.x > screen_size.x:
		$Foreground.position.x += screen_size.x

func _spawn_obstacles() -> void:
	while distance_travelled >= next_obstacle_spawn_distance:
		# Tính toán khoảng cách dựa trên tốc độ hiện tại và vật lý
		var jump_distance := current_speed * JUMP_DURATION

		# Độ khó tăng dần: safety factor giảm từ MAX -> MIN theo distance
		var progress := 1.0 - exp(-distance_travelled * DIFFICULTY_CURVE)
		var safety_factor : float = lerp(MAX_SAFETY_FACTOR, MIN_SAFETY_FACTOR, progress)

		# Khoảng cách spawn an toàn
		var min_gap : float = jump_distance * safety_factor * 0.9
		var max_gap : float = jump_distance * safety_factor * 1.1

		# Spawn ngẫu nhiên thorn (đất) hoặc enemy (bay)
		var spawn_enemy := randf() > 0.5
		var obstacle: Node2D
		var y_position: float

		if spawn_enemy:
			obstacle = ENEMY_SCENE.instantiate()
			y_position = ENEMY_Y
		else:
			obstacle = THORN_SCENE.instantiate()
			y_position = THORN_Y

		obstacle.position = Vector2($Camera2D.position.x + screen_size.x + SPAWN_BUFFER_X, y_position)
		obstacle.player_hit.connect(_on_obstacle_hit)
		add_child(obstacle)
		spawned_obstacles.append(obstacle)

		var spawn_gap := randf_range(min_gap, max_gap)
		next_obstacle_spawn_distance += spawn_gap
   
func _cleanup_obstacles() -> void:
	for i in range(spawned_obstacles.size() - 1, -1, -1):
		var obstacle := spawned_obstacles[i]
		if obstacle.position.x < $Camera2D.position.x - CLEANUP_BUFFER_X:
			spawned_obstacles.remove_at(i)
			obstacle.queue_free()

func _spawn_coffee() -> void:
	while distance_travelled >= next_coffee_spawn_distance:
		if randf() < COFFEE_SPAWN_CHANCE:
			var coffee := COFFEE_SCENE.instantiate() as Node2D
			coffee.position = Vector2($Camera2D.position.x + screen_size.x + SPAWN_BUFFER_X, COFFEE_Y)
			coffee.collected.connect(_on_coffee_collected)
			add_child(coffee)
			spawned_collectibles.append(coffee)

		# Spawn coffee mỗi 300-500 pixels
		var coffee_gap := randf_range(300.0, 500.0)
		next_coffee_spawn_distance += coffee_gap

func _cleanup_collectibles() -> void:
	for i in range(spawned_collectibles.size() - 1, -1, -1):
		var collectible := spawned_collectibles[i]
		if collectible == null or collectible.position.x < $Camera2D.position.x - CLEANUP_BUFFER_X:
			spawned_collectibles.remove_at(i)
			if collectible != null:
				collectible.queue_free()

func _on_obstacle_hit() -> void:
	$Player.die()
	$AudioManager.play_hit()

func _on_coffee_collected(points: int) -> void:
	score += points
	$UI.update_score(score)
	# TODO: Thêm sound effect cho coffee nếu có

func _on_player_died() -> void:
	game_over = true
	$UI.show_game_over(score)

func _on_restart_requested() -> void:
	get_tree().reload_current_scene()
