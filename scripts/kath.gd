extends CharacterBody2D
## Side-view movement for Kath. The node origin marks her feet on the scene floor.

const IDLE_FRAMES: SpriteFrames = preload("res://prologue-asset-pack-v1/godot/frames/kath-idle.tres")
const WALK_FRAMES: SpriteFrames = preload("res://prologue-asset-pack-v1/godot/frames/kath-walk.tres")
const DISPLAY_HEIGHT: float = 232.0
const IDLE_SOURCE_HEIGHT: float = 771.0
const WALK_SOURCE_HEIGHT: float = 484.0

@export var walk_speed: float = 230.0
@export var acceleration: float = 900.0
@export var deceleration: float = 1200.0
@export var floor_y: float = 778.0
@export var left_limit: float = 56.0
@export var right_limit: float = 1616.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_walking: bool = false


func _ready() -> void:
	position.y = floor_y
	_set_animation(false)


func _physics_process(delta: float) -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	var target_speed: float = direction * walk_speed
	var rate: float = acceleration if direction != 0.0 else deceleration
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)
	velocity.y = 0.0
	move_and_slide()

	# This scene has no vertical traversal. Keep the feet aligned with the painted floor.
	position.x = clampf(position.x, left_limit, right_limit)
	position.y = floor_y
	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0
	_set_animation(absf(velocity.x) > 8.0)


func _set_animation(walking: bool) -> void:
	if animated_sprite.sprite_frames == (WALK_FRAMES if walking else IDLE_FRAMES):
		return
	is_walking = walking
	animated_sprite.sprite_frames = WALK_FRAMES if walking else IDLE_FRAMES
	var source_height: float = WALK_SOURCE_HEIGHT if walking else IDLE_SOURCE_HEIGHT
	animated_sprite.scale = Vector2.ONE * (DISPLAY_HEIGHT / source_height)
	animated_sprite.offset = Vector2(0.0, -source_height / 2.0)
	animated_sprite.play("default")
