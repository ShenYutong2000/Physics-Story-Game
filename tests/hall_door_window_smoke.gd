extends SceneTree
## Step 4: the door/window patrol is one check with two independent operations.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.notes.clear()
	state.flags.clear()
	var hall: Node2D = await _new_hall()
	if hall.nearest_hotspot(476.0) != hall.high_window:
		_fail("The high window cannot be reached from its floor position.")
		return
	# Canceling the window close-up makes no change.
	hall._inspect(hall.high_window)
	await create_timer(0.3).timeout
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if bool(state.flags.get("hall_window_fixed", false)) or state.has_note(&"archive-door"):
		_fail("Esc recorded an untouched window.")
		return
	# Fix the window first. The door/window item remains empty in the journal.
	hall._inspect(hall.high_window)
	await create_timer(0.3).timeout
	hall._unhandled_input(_key(KEY_E))
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	hall._unhandled_input(_key(KEY_ENTER))
	if not bool(state.flags.get("hall_window_fixed", false)) or state.has_note(&"archive-door") \
		or not hall.window_catch_world.secured or hall.door_bolt_world.secured or state.hall_checks_complete():
		_fail("Fixing only the window completed the combined patrol item.")
		return
	hall._show_journal()
	if not hall.ui.journal_progress.text.contains("[ ]  Doors and windows (door loose · window fixed)"):
		_fail("The journal did not show the partial door/window state.")
		return
	hall.ui.hide_modals()
	hall.queue_free()
	await process_frame
	# A new hall instance must restore the world prop and playable close-up.
	hall = await _new_hall()
	if not hall.window_catch_world.secured or hall.door_bolt_world.secured:
		_fail("The window state was lost when returning to the hall.")
		return
	hall._inspect(hall.high_window)
	await create_timer(0.3).timeout
	if not hall.focus.completed or hall.focus.selected_action() != &"":
		_fail("The revisited window no longer looks fixed.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	hall._inspect(hall.archive_door)
	await create_timer(0.3).timeout
	hall._unhandled_input(_key(KEY_E))
	if not state.has_note(&"archive-door") or state.notes.size() != 1 or not hall.door_bolt_world.secured:
		_fail("Fastening the second latch did not record exactly one combined check.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	hall._unhandled_input(_key(KEY_ENTER))
	if hall.mode != &"roam":
		_fail("The final response did not return control to Kath.")
		return
	hall.queue_free()
	await process_frame
	hall = await _new_hall()
	if not hall.window_catch_world.secured or not hall.door_bolt_world.secured or state.notes.size() != 1:
		_fail("Both fixtures did not persist on a second hall entry.")
		return
	print("HALL_DOOR_WINDOW_SMOKE_OK: reverse order, cancellation, partial journal, scene revisit, unique combined check")
	hall.queue_free()
	await process_frame
	quit(0)


func _new_hall() -> Node2D:
	var hall: Node2D = HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	if hall.mode == &"dialogue":
		hall._close_dialogue(false)
	return hall


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("HALL_DOOR_WINDOW_SMOKE_FAIL: " + message)
	quit(1)
