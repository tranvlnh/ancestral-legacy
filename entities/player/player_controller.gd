extends CharacterBody2D

enum MoveState { IDLE, RUNNING, AIRBORNE, DEAD }
var move_state: MoveState = MoveState.IDLE

@export var stats: PlayerStats

func _physics_process(delta: float) -> void:
	#if stats == null:
		#return
	#if move_state == MoveState.RUNNING:
	velocity.y += stats.gravity * delta

	if Input.is_action_just_pressed("ui_accept")  and is_on_floor():
		velocity.y = stats.jump_velocity
	
	move_and_slide()
