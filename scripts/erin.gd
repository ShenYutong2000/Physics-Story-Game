extends Node2D
## Erin's feet are the node origin. This is a reusable Chapter I NPC, not a story trigger.

const IDLE: Texture2D = preload("res://chapter1-assets/characters/erin/idle.png")
const WALK_A: Texture2D = preload("res://chapter1-assets/characters/erin/walk-a.png")
const WALK_B: Texture2D = preload("res://chapter1-assets/characters/erin/walk-b.png")
const REPAIR: Texture2D = preload("res://chapter1-assets/characters/erin/repair.png")

const DISPLAY_HEIGHT := 308.0
const IDLE_ART_HEIGHT := 1438.0
const WALK_FRAME_TIME := 0.22

@onready var sprite: Sprite2D = $Sprite2D

var walking := false
var repairing := false
var _walk_time := 0.0
var _walk_frame := false


func _ready() -> void:
	_show_pose(&"idle")


func _process(delta: float) -> void:
	if not walking or repairing:
		return
	_walk_time += delta
	if _walk_time >= WALK_FRAME_TIME:
		_walk_time = 0.0
		_walk_frame = not _walk_frame
		_show_pose(&"walk_b" if _walk_frame else &"walk_a")


func set_walking(value: bool) -> void:
	walking = value
	_walk_time = 0.0
	_walk_frame = false
	if not repairing:
		_show_pose(&"walk_a" if walking else &"idle")


func set_repairing(value: bool) -> void:
	repairing = value
	if repairing:
		walking = false
	_show_pose(&"repair" if repairing else &"idle")


func _show_pose(pose: StringName) -> void:
	if sprite == null:
		return
	var art_bounds: Rect2i
	match pose:
		&"walk_a":
			sprite.texture = WALK_A
			art_bounds = Rect2i(97, 103, 853, 1422)
		&"walk_b":
			sprite.texture = WALK_B
			art_bounds = Rect2i(194, 102, 569, 1412)
		&"repair":
			sprite.texture = REPAIR
			art_bounds = Rect2i(187, 83, 768, 1440)
		_:
			sprite.texture = IDLE
			art_bounds = Rect2i(198, 104, 552, 1438)
	sprite.region_enabled = true
	sprite.region_rect = Rect2(art_bounds)
	sprite.centered = false
	sprite.offset = Vector2(-art_bounds.size.x * 0.5, -art_bounds.size.y)
	sprite.scale = Vector2.ONE * (DISPLAY_HEIGHT / IDLE_ART_HEIGHT)
