extends "res://tests/support/story_test.gd"
## Save failures must leave the paused game open and show a visible message.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _run() -> void:
	state.save_path_override = "user://stage6-missing-folder/checkpoint.json"
	state.persistence_enabled = true
	var hall = HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	hall._set_mode(&"paused")
	hall.ui.show_pause()
	state._input(_key(KEY_Q))
	if not hall.ui.pause_save_error.visible or hall.mode != &"paused":
		push_error("STAGE6_SAVE_FAILURE_FAIL: save failure was not visible in pause.")
		quit(1)
		return
	state.persistence_enabled = false
	state.save_path_override = ""
	print("STAGE6_SAVE_FAILURE_OK: failed write kept the game paused")
	quit(0)
