extends Node2D
## Standalone art/scale review. It does not change PrologueState or story progress.

@onready var erin: Node2D = $Erin

var pose_index := 0


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact") or (event is InputEventKey and event.echo):
		return
	pose_index = (pose_index + 1) % 3
	erin.set_repairing(pose_index == 2)
	erin.set_walking(pose_index == 1)
	get_viewport().set_input_as_handled()
