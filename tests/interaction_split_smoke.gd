extends SceneTree

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.notes.clear()
	state.flags.clear()
	state.pending_spawn_tag = &""
	var hall := HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	hall._close_dialogue(false)

	# One key handles nearby context; F has no binding.
	hall.kath.position.x = hall.get_node("OldClock").approach_x
	hall._process(0.0)
	if hall.ui.prompt.text.find("E  INSPECT") == -1 or hall.ui.prompt.text.find("F  ") != -1:
		_fail("The clock should show only the unified E prompt.")
		return
	hall._unhandled_input(_key(KEY_F))
	if hall.mode != &"roam" or state.notes.size() != 0:
		_fail("F activated the inspect-only clock.")
		return
	hall._unhandled_input(_key(KEY_E))
	if hall.mode != &"dialogue":
		_fail("E did not inspect the clock.")
		return
	hall._close_dialogue(false)

	# An available doorway uses the same E key to enter.
	for note_id in [&"archive-door", &"clock-housing", &"maintenance-sheet"]:
		state.add_note_once(note_id, String(note_id), "Observation")
	hall.kath.position.x = hall.archive_door.approach_x
	hall._process(0.0)
	if hall.ui.prompt.text.find("E  ENTER") == -1 or hall.ui.prompt.text.find("F  ") != -1:
		_fail("The available door did not show a single E entry prompt.")
		return
	var note_count: int = state.notes.size()
	hall.ui.hint.visible = false
	hall._unhandled_input(_key(KEY_F))
	if current_scene != hall or hall.mode != &"roam" or state.notes.size() != note_count or hall.ui.hint.visible:
		_fail("F at the open door should not travel or change progress.")
		return
	hall._unhandled_input(_key(KEY_E))
	await process_frame
	await process_frame
	if current_scene == null or current_scene.name != "MachineRoom":
		_fail("E did not enter the machine room.")
		return
	print("INTERACTION_SINGLE_KEY_OK: E inspects or acts, F is inactive")
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("INTERACTION_SPLIT_SMOKE_FAIL: " + message)
	quit(1)
