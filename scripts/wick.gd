extends Node2D
## Wick is a silent mechanical-world companion; its light is a visual reaction.

const PERCH: SpriteFrames = preload("res://prologue-asset-pack-v1/godot/frames/wick-perch.tres")
const FLIGHT: SpriteFrames = preload("res://prologue-asset-pack-v1/godot/frames/wick-flight-v2.tres")
# Canonical rendered height for Wick in every scene that instances scenes/wick.tscn.
const DISPLAY_HEIGHT := 130.0
const PERCH_SOURCE_HEIGHT := 829.0
const FLIGHT_SOURCE_HEIGHT := 566.0

@export var kath_path: NodePath = NodePath("../Kath")

@onready var moth: AnimatedSprite2D = $AnimatedSprite2D
@onready var kath: CharacterBody2D = get_node(kath_path)

var reaction_time := 0.0
var reaction_x := 0.0
var reaction_y := 0.0
var flying := false


func _ready() -> void:
	position = kath.position + Vector2(80, -225)
	_set_flying(false)


func _process(delta: float) -> void:
	if reaction_time > 0.0:
		reaction_time = maxf(0.0, reaction_time - delta)
		_set_flying(true)
		position = position.lerp(Vector2(reaction_x, reaction_y + sin(Time.get_ticks_msec() * 0.013) * 7.0), minf(delta * 5.0, 1.0))
		moth.modulate = Color(1.25, 1.13, 0.86)
		return

	var facing_left: bool = kath.get_node("AnimatedSprite2D").flip_h
	var offset_x: float = 90.0 if facing_left else -90.0
	var moving: bool = kath.is_walking
	_set_flying(moving)
	var bob: float = sin(Time.get_ticks_msec() * 0.008) * 8.0 if moving else 0.0
	position = position.lerp(kath.position + Vector2(offset_x, -225.0 + bob), minf(delta * (5.0 if moving else 8.0), 1.0))
	moth.modulate = Color.WHITE


func react_to(world_x: float, world_y: float) -> void:
	reaction_x = world_x
	reaction_y = world_y
	reaction_time = 1.8


func _set_flying(value: bool) -> void:
	if moth.sprite_frames == (FLIGHT if value else PERCH):
		return
	flying = value
	moth.sprite_frames = FLIGHT if value else PERCH
	var source_height: float = FLIGHT_SOURCE_HEIGHT if value else PERCH_SOURCE_HEIGHT
	moth.scale = Vector2.ONE * (DISPLAY_HEIGHT / source_height)
	moth.offset = Vector2(0.0, -source_height / 2.0)
	moth.play("default")
