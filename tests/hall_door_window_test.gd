extends "res://tests/support/story_test.gd"
## Step 4: the door/window patrol is one check with two independent operations.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _run() -> void:
	state.notes.clear()
	state.flags.clear()
	var hall: Node2D = await _new_hall()
	if hall.nearest_hotspot(476.0) != hall.high_window:
		_fail("The high window cannot be reached from its floor position.")
		return
	# Canceling the window close-up makes no change.
	hall._inspect(hall.high_window)
	await create_timer(FOCUS_IN).timeout
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if bool(state.flags.get("hall_window_fixed", false)) or state.has_note(&"archive-door"):
		_fail("Esc recorded an untouched window.")
		return
	# Fix the window first. The door/window item remains empty in the journal.
	hall._inspect(hall.high_window)
	await create_timer(FOCUS_IN).timeout
	hall._unhandled_input(_key(KEY_E))
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
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
	await create_timer(FOCUS_IN).timeout
	if not hall.focus.completed or hall.focus.selected_action() != &"":
		_fail("The revisited window no longer looks fixed.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	hall._inspect(hall.archive_door)
	await create_timer(FOCUS_IN).timeout
	await _hold_on(hall, KEY_E, SLIDE_HOLD)
	if not state.has_note(&"archive-door") or state.notes.size() != 1 or not hall.door_bolt_world.secured:
		_fail("Fastening the second latch did not record exactly one combined check.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
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
