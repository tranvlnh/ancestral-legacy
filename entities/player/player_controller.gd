extends CharacterBody2D

signal died

enum MoveState { IDLE, RUNNING, AIRBORNE, DEAD }
var move_state: MoveState = MoveState.RUNNING

@export var stats: PlayerStats

var _jump_pressed: bool = false

func _ready() -> void:
	if stats == null:
		push_error("PlayerStats not assigned!")

func _physics_process(delta: float) -> void:
	if move_state == MoveState.DEAD:
		return

	# Apply gravity
	velocity.y += stats.gravity * delta
	velocity.y = min(velocity.y, stats.max_fall_speed)

	# Jump input
	if (Input.is_action_just_pressed("ui_accept") or Input.is_action_just_pressed("jump") or _jump_pressed):
		_jump_pressed = false
		if is_on_floor():
			velocity.y = stats.jump_velocity
			move_state = MoveState.AIRBORNE
			_play_jump_sound()

	# Update state
	if is_on_floor() and move_state == MoveState.AIRBORNE:
		move_state = MoveState.RUNNING

	move_and_slide()

func _input(event: InputEvent) -> void:
	# Web export fires PointerEvent → InputEventMouseButton, not InputEventScreenTouch
	if event is InputEventScreenTouch and event.pressed:
		_jump_pressed = true
		_request_landscape()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_jump_pressed = true
		_request_landscape()

func _request_landscape() -> void:
	if DisplayServer.get_name() != "web":
		return
	# screen.orientation.lock needs user gesture — call once per tap
	JavaScriptBridge.eval("""
		if (screen.orientation && !window._landscape_locked) {
			screen.orientation.lock('landscape').catch(function(){});
			window._landscape_locked = true;
		}
	""", false)

func die() -> void:
	if move_state != MoveState.DEAD:
		move_state = MoveState.DEAD
		velocity = Vector2.ZERO
		died.emit()

func _play_jump_sound() -> void:
	var audio_manager = get_tree().root.get_node_or_null("Main/AudioManager")
	if audio_manager:
		audio_manager.play_jump()
