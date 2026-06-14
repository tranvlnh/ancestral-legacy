extends Node2D

const THORN_SCENE: PackedScene = preload("res://entities/obstacle/thorn.tscn")
const ENEMY_SCENE: PackedScene = preload("res://entities/obstacle/enemy.tscn")
const COFFEE_SCENE: PackedScene = preload("res://entities/collectible/coffee.tscn")

@export var player_stats: PlayerStats

# Game speed constants
const BASE_SPEED: float = 150.0
const SPEED_SCALE_RATE: float = 0.8
const MAX_SPEED: float = 400.0

# Spawn algorithm constants - dùng từ player_stats
const MIN_SAFETY_FACTOR: float = 1.8
const MAX_SAFETY_FACTOR: float = 2.5
const DIFFICULTY_CURVE: float = 0.0015

const SPAWN_BUFFER_X: float = 80.0
const CLEANUP_BUFFER_X: float = 80.0
const THORN_Y: float = 144.0
const ENEMY_Y: float = 80.0
const COFFEE_Y_FLOOR: float = 142.0
const COFFEE_Y_HIGH: float = 90.0
const COFFEE_FLOOR_CHANCE: float = 0.65
const COFFEE_SPAWN_CHANCE: float = 0.4

# Coffee spawn physics-based constants
const COFFEE_MIN_GAP: float = 60.0
const COFFEE_MAX_GAP: float = 140.0

var screen_size: Vector2
var distance_travelled: float = 0.0
var next_obstacle_spawn_distance: float = 0.0
var next_coffee_spawn_distance: float = 300.0
var spawned_obstacles: Array[Node2D] = []
var spawned_collectibles: Array[Node2D] = []
var game_over: bool = false
var score: float = 0.0
var current_speed: float = BASE_SPEED

func _ready() -> void:
	_setup_input_actions()
	screen_size = get_viewport_rect().size
	if player_stats == null:
		player_stats = PlayerStats.new()
	$Player.died.connect(_on_player_died)
	$UI.restart_requested.connect(_on_restart_requested)

func _setup_input_actions() -> void:
	if InputMap.has_action("jump"):
		return
	InputMap.add_action("jump")
	# Spacebar
	var key := InputEventKey.new()
	key.keycode = KEY_SPACE
	InputMap.action_add_event("jump", key)
	# Tap anywhere on screen (mobile)
	var touch := InputEventScreenTouch.new()
	touch.pressed = true
	InputMap.action_add_event("jump", touch)
	# Left click (desktop fallback)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("jump", mouse)

func _process(delta: float) -> void:
	if game_over:
		return

	current_speed = BASE_SPEED + (SPEED_SCALE_RATE * (distance_travelled / 100.0))
	current_speed = min(current_speed, MAX_SPEED)
	var movement := current_speed * delta

	$Player.position.x += movement
	$Camera2D.position.x += movement
	distance_travelled += movement
	score += movement * 0.1
	$UI.update_score(int(score))

	_spawn_obstacles()
	_spawn_coffee()
	_cleanup_obstacles()
	_cleanup_collectibles()

	if $Camera2D.position.x - $Foreground.position.x > screen_size.x:
		$Foreground.position.x += screen_size.x

func _spawn_obstacles() -> void:
	while distance_travelled >= next_obstacle_spawn_distance:
		# Tính toán khoảng cách dựa trên tốc độ hiện tại và vật lý
		var jump_duration : float = 2.0 * abs(player_stats.jump_velocity) / player_stats.gravity
		var jump_distance := current_speed * jump_duration

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
			# Tìm obstacle gần nhất để tính toán vị trí spawn
			var nearest_obstacle: Node2D = null
			var min_dx: float = INF
			for obstacle in spawned_obstacles:
				var dx: float = obstacle.position.x - ($Camera2D.position.x + screen_size.x)
				if dx > -SPAWN_BUFFER_X * 2 and dx < min_dx:
					min_dx = dx
					nearest_obstacle = obstacle

			# Tính toán vị trí spawn dựa trên vật lý
			var coffee_x: float
			var coffee_y: float

			if nearest_obstacle != null:
				# Spawn sau obstacle một khoảng tính toán được
				var gap: float = randf_range(COFFEE_MIN_GAP, COFFEE_MAX_GAP)
				coffee_x = nearest_obstacle.position.x + gap

				# Tính chiều cao reachable dựa trên vận tốc và trọng lực
				# Sử dụng công thức projectile motion: y = v0*t - 0.5*g*t^2
				var time_to_obstacle: float = gap / current_speed
				var max_reachable_height: float = abs(player_stats.jump_velocity) * time_to_obstacle - 0.5 * player_stats.gravity * pow(time_to_obstacle, 2)

				# Chọn Y position dựa trên độ cao reachable
				if max_reachable_height > 40.0:
					# Có thể nhảy qua, spawn trên cao
					coffee_y = COFFEE_Y_HIGH if randf() < 0.4 else COFFEE_Y_FLOOR
				else:
					# Không thể nhảy, spawn sát đất để nhặt dễ
					coffee_y = COFFEE_Y_FLOOR
			else:
				# Không có obstacle, spawn ngẫu nhiên như cũ
				coffee_x = $Camera2D.position.x + screen_size.x + SPAWN_BUFFER_X
				coffee_y = COFFEE_Y_FLOOR if randf() < COFFEE_FLOOR_CHANCE else COFFEE_Y_HIGH

			var coffee := COFFEE_SCENE.instantiate() as Node2D
			coffee.position = Vector2(coffee_x, coffee_y)
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
	$UI.update_score(int(score))

func _on_player_died() -> void:
	game_over = true
	$UI.show_game_over(int(score))

func _on_restart_requested() -> void:
	get_tree().reload_current_scene()
