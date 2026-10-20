extends CharacterBody2D
## Side-view movement for Kath. The node origin marks her feet on the scene floor.

const IDLE_FRAMES: SpriteFrames = preload("res://prologue-asset-pack-v1/godot/frames/kath-idle.tres")
const WALK_FRAMES: SpriteFrames = preload("res://prologue-asset-pack-v1/godot/frames/kath-walk.tres")
const CLIMB_FRAMES: SpriteFrames = preload("res://prologue-asset-pack-v1/godot/frames/kath-climb.tres")
# Canonical rendered height for Kath in every scene that instances scenes/kath.tscn.
const DISPLAY_HEIGHT: float = 232.0 * 1.3
const IDLE_SOURCE_HEIGHT: float = 771.0
const WALK_SOURCE_HEIGHT: float = 484.0
const CLIMB_SOURCE_HEIGHT: float = 753.0

@export var walk_speed: float = 230.0
@export var acceleration: float = 900.0
@export var deceleration: float = 1200.0
@export var push_speed: float = 150.0
@export var climb_speed: float = 145.0
@export var floor_y: float = 778.0
## Optional ground slope. floor_y is the ground height at floor_anchor_x.
@export var floor_anchor_x: float = 0.0
@export var floor_slope: float = 0.0
@export var left_limit: float = 56.0
@export var right_limit: float = 1616.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var is_walking: bool = false
var controls_enabled: bool = true
var locomotion_mode: StringName = &"walk"
var push_min_x: float = 0.0
var push_max_x: float = 0.0
var push_ladder_offset: float = 80.0
var climb_anchor_x: float = 0.0
var climb_top_y: float = 0.0
var climb_bottom_y: float = 0.0


func _ready() -> void:
	position.y = floor_height_at(position.x)
	_set_animation(false)


func _physics_process(delta: float) -> void:
	if not controls_enabled:
		velocity = Vector2.ZERO
		_set_animation(false)
		return
	if locomotion_mode == &"push":
		var push_direction: float = Input.get_axis("move_left", "move_right")
		position.x = clampf(position.x + push_direction * push_speed * delta, push_min_x, push_max_x)
		position.y = floor_height_at(position.x)
		if push_direction != 0.0:
			animated_sprite.flip_h = push_direction < 0.0
		_set_animation(absf(push_direction) > 0.01)
		return
	if locomotion_mode == &"climb":
		var climb_direction: float = Input.get_axis("move_down", "move_up")
		position.x = climb_anchor_x
		position.y = clampf(position.y - climb_direction * climb_speed * delta, climb_top_y, climb_bottom_y)
		velocity = Vector2.ZERO
		_set_climb_animation()
		is_walking = absf(climb_direction) > 0.01
		return
	var direction: float = Input.get_axis("move_left", "move_right")
	var target_speed: float = direction * walk_speed
	var rate: float = acceleration if direction != 0.0 else deceleration
	velocity.x = move_toward(velocity.x, target_speed, rate * delta)
	velocity.y = 0.0
	move_and_slide()

	# This scene has no vertical traversal. Keep the feet aligned with the painted floor.
	position.x = clampf(position.x, left_limit, right_limit)
	position.y = floor_height_at(position.x)
	if direction != 0.0:
		animated_sprite.flip_h = direction < 0.0
	_set_animation(absf(velocity.x) > 8.0)


func floor_height_at(world_x: float) -> float:
	return floor_y + (world_x - floor_anchor_x) * floor_slope


func begin_pushing(ladder_x: float, minimum_ladder_x: float, maximum_ladder_x: float, horizontal_offset: float = 80.0) -> void:
	locomotion_mode = &"push"
	push_ladder_offset = horizontal_offset
	push_min_x = minimum_ladder_x - horizontal_offset
	push_max_x = maximum_ladder_x - horizontal_offset
	position = Vector2(ladder_x - horizontal_offset, floor_height_at(ladder_x - horizontal_offset))
	velocity = Vector2.ZERO


func stop_pushing(ladder_x: float) -> void:
	locomotion_mode = &"walk"
	position = Vector2(ladder_x - push_ladder_offset, floor_height_at(ladder_x - push_ladder_offset))
	velocity = Vector2.ZERO
	_set_animation(false)


func begin_climbing(ladder_x: float, top_y: float, bottom_y: float, start_y: float = -1.0) -> void:
	locomotion_mode = &"climb"
	climb_anchor_x = ladder_x
	climb_top_y = top_y
	climb_bottom_y = bottom_y
	position = Vector2(ladder_x, clampf(start_y if start_y >= 0.0 else bottom_y, top_y, bottom_y))
	velocity = Vector2.ZERO
	_set_climb_animation()


func stop_climbing() -> void:
	locomotion_mode = &"walk"
	position = Vector2(position.x, floor_height_at(position.x))
	velocity = Vector2.ZERO
	_set_animation(false)


func _set_animation(walking: bool) -> void:
	var frames: SpriteFrames = WALK_FRAMES if walking else IDLE_FRAMES
	if animated_sprite.sprite_frames == frames:
		is_walking = walking
		return
	is_walking = walking
	animated_sprite.sprite_frames = frames
	var source_height: float = WALK_SOURCE_HEIGHT if walking else IDLE_SOURCE_HEIGHT
	animated_sprite.scale = Vector2.ONE * (DISPLAY_HEIGHT / source_height)
	animated_sprite.offset = Vector2(0.0, -source_height / 2.0)
	animated_sprite.play("default")


func _set_climb_animation() -> void:
	is_walking = false
	if animated_sprite.sprite_frames != CLIMB_FRAMES:
		animated_sprite.sprite_frames = CLIMB_FRAMES
		animated_sprite.scale = Vector2.ONE * (DISPLAY_HEIGHT / CLIMB_SOURCE_HEIGHT)
		animated_sprite.offset = Vector2(0.0, -CLIMB_SOURCE_HEIGHT / 2.0)
		animated_sprite.play("default")
