class_name PlayerController
extends CharacterBody2D

@export var walk_speed: float = 80.0
@export var run_speed: float = 120.0
@export var jump_velocity: float = -250.0
@export var gravity: float = 980.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var direction := 0.0

	if Input.is_action_pressed("move_left"):
		direction -= 1.0

	if Input.is_action_pressed("move_right"):
		direction += 1.0

	var is_running := Input.is_action_pressed("run")
	var current_speed := run_speed if is_running else walk_speed

	velocity.x = direction * current_speed

	if not is_on_floor():
		velocity.y += gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	move_and_slide()
	update_animation(direction, is_running)
	update_facing_direction(direction)


func update_animation(direction: float, is_running: bool) -> void:
	if not is_on_floor():
		if velocity.y < 0:
			play_player_animation(&"jump")
		else:
			play_player_animation(&"fall", &"jump")
		return

	if direction != 0:
		if is_running:
			play_player_animation(&"run")
		else:
			play_player_animation(&"walk")
	else:
		play_player_animation(&"idle")


func play_player_animation(animation_name: StringName, fallback_name: StringName = &"idle") -> void:
	if animated_sprite.sprite_frames.has_animation(animation_name):
		if animated_sprite.animation != animation_name:
			animated_sprite.play(animation_name)
	elif animated_sprite.sprite_frames.has_animation(fallback_name):
		if animated_sprite.animation != fallback_name:
			animated_sprite.play(fallback_name)


func update_facing_direction(direction: float) -> void:
	if direction > 0:
		animated_sprite.flip_h = false
	elif direction < 0:
		animated_sprite.flip_h = true
