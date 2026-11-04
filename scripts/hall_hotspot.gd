extends Node2D
## A reachable point in a side-view room. Height never affects the reach test.

signal exit_requested(destination_scene: String, spawn_tag: String)

@export var interaction_id: StringName
@export var display_name: String = "Inspect"
@export var approach_x: float = 0.0
@export var reach_radius: float = 115.0
@export var content_key: StringName
@export var destination_scene: String = ""
@export var spawn_tag: String = ""
@export var discovery_anchor := Vector2(-1.0, -1.0)


func distance_from(feet_x: float) -> float:
	return absf(feet_x - approach_x)


func is_reachable(feet_x: float) -> bool:
	return distance_from(feet_x) <= reach_radius


func marker_position() -> Vector2:
	if discovery_anchor.x >= 0.0 and discovery_anchor.y >= 0.0:
		return discovery_anchor
	for child in get_children():
		if child is Sprite2D and child.texture != null:
			return child.global_position + Vector2(0.0, -22.0)
		if child is AnimatedSprite2D and child.sprite_frames != null:
			return child.global_position + Vector2(0.0, -22.0)
	return Vector2(approach_x, clampf(global_position.y - 145.0, 145.0, 690.0))


func request_exit() -> void:
	if not destination_scene.is_empty():
		exit_requested.emit(destination_scene, spawn_tag)
