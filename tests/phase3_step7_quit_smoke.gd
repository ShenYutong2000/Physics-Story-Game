extends SceneTree
## The actual pause-screen Q path flushes the latest room state before quitting.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const TEST_SAVE := "user://phase3-step7-quit-test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.save_path_override = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	state.persistence_enabled = true
	var hall = HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	state.flags["pause_quit_test"] = true
	hall._set_mode(&"paused")
	state._input(_key(KEY_Q))
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(TEST_SAVE))
	if not saved is Dictionary or saved.get("scene") != "res://scenes/library_hall.tscn" or not saved.get("flags", {}).get("pause_quit_test", false):
		push_error("PHASE3_STEP7_QUIT_FAIL: Q did not flush the latest state.")
		quit(1)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	state.persistence_enabled = false
	state.save_path_override = ""
	current_scene = null
	hall.free()
	print("PHASE3_STEP7_QUIT_OK: pause-screen Q flushed the current room and flags")


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event
