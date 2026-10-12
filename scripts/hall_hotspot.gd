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


func distance_from(feet_x: float) -> float:
	return absf(feet_x - approach_x)


func is_reachable(feet_x: float) -> bool:
	return distance_from(feet_x) <= reach_radius


func request_exit() -> void:
	if not destination_scene.is_empty():
		exit_requested.emit(destination_scene, spawn_tag)
