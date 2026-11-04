extends SceneTree
## Step 7: live checks, early emergency reading, cancellable stamp, archive, gate, revisit.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const OUTPUT := "res://prologue-asset-pack-v1/hall-closeups-v2/review-captures/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.persistence_enabled = false
	state.flags.clear()
	state.notes.clear()
	var hall: Node2D = await _new_hall()
	if not await _capture("interactive-book-hall"):
		return
	hall.kath.position.x = 1212.0
	await _tap(KEY_E)
	if hall.mode != &"round_book" or hall.round_book.page_kind != &"current" or hall.kath.controls_enabled or hall.round_book_world.filed:
		_fail("The task book did not open exclusively from the desk.")
		return
	if not await _capture("interactive-book-unchecked"):
		return
	hall._unhandled_input(_key(KEY_E))
	if state.hall_checks_complete() or hall.round_book.busy:
		_fail("An incomplete checklist accepted the stamp.")
		return
	hall._unhandled_input(_key(KEY_RIGHT))
	if hall.round_book.page_kind != &"emergency" or not state.has_note(&"emergency-procedure"):
		_fail("The red tab was not available before filing.")
		return
	if not await _capture("interactive-book-emergency"):
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if hall.mode != &"roam" or state.flags.get("hall_round_filed", false):
		_fail("Closing the early emergency page filed the round.")
		return
	for id in state.HALL_NOTE_IDS:
		state.add_note_once(id, String(id), "Completed during test")
	state.flags["hall_door_latched"] = true
	state.flags["hall_window_fixed"] = true
	state.flags["hall_clock_wound"] = true
	state.flags["hall_east_key_sorted"] = true
	if state.hall_checks_complete():
		_fail("Three completed checks opened the machine room before the stamp.")
		return
	await _tap(KEY_E)
	if not hall.round_book.tasks.all(func(done: bool) -> bool: return done):
		_fail("The book did not reflect all three finished tasks.")
		return
	if not await _capture("interactive-book-ready"):
		return
	hall._unhandled_input(_key(KEY_E))
	if not hall.round_book.busy:
		_fail("The stamp animation did not start.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.22).timeout
	if state.flags.get("hall_round_filed", false) or state.has_note(&"evening-round-filed"):
		_fail("Esc during the stamp committed an unfinished operation.")
		return
	await _tap(KEY_E)
	hall._unhandled_input(_key(KEY_E))
	await create_timer(0.02).timeout
	if not await _capture("interactive-book-stamping"):
		return
	await create_timer(0.42).timeout
	if not hall.round_book.archived_stamp.visible or not await _capture("interactive-book-stamped"):
		_fail("The filed impression was not visible before the new blank page.")
		return
	await create_timer(0.55).timeout
	if not state.hall_checks_complete() or not state.has_note(&"evening-round-filed") or hall.round_book.page_kind != &"current" or not hall.round_book_world.filed:
		_fail("The completed stamp did not file and clear the task page.")
		return
	if not await _capture("interactive-book-blank"):
		return
	hall._unhandled_input(_key(KEY_RIGHT))
	if hall.round_book.page_kind != &"archive" or not hall.round_book.archived_stamp.visible:
		_fail("The archived checked page cannot be reviewed.")
		return
	if not await _capture("interactive-book-archive"):
		return
	hall._unhandled_input(_key(KEY_RIGHT))
	if hall.round_book.page_kind != &"emergency":
		_fail("The red tab was lost after filing.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if hall.mode != &"dialogue" or not hall.completion_played:
		_fail("Filing did not trigger the single hall completion response.")
		return
	hall._unhandled_input(_key(KEY_ENTER))
	for i in 3:
		await process_frame
	hall.kath.position.x = 760.0
	if not await _capture("interactive-book-hall-after"):
		return
	if hall.mode != &"roam" or hall.archive_door.display_name != "Machine Room":
		_fail("The filed round did not unlock the machine-room door (mode=%s, label=%s, complete=%s)." % [hall.mode, hall.archive_door.display_name, state.hall_checks_complete()])
		return
	var note_count: int = state.notes.size()
	hall.queue_free()
	await process_frame
	hall = await _new_hall()
	hall.kath.position.x = 1212.0
	await _tap(KEY_E)
	if not hall.round_book.filed or hall.round_book.page_kind != &"current" or not hall.round_book.blank_label.visible or not hall.round_book_world.filed:
		_fail("Returning to the hall lost the blank current page.")
		return
	hall._unhandled_input(_key(KEY_E))
	if hall.round_book.page_kind != &"emergency" or state.notes.size() != note_count:
		_fail("Repeating the filed-book action duplicated a note or stamp.")
		return
	print("HALL_ROUND_BOOK_SMOKE_OK: live checklist, early red tab, cancelled stamp, blank current page, archive, gate, revisit")
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


func _capture(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		root.size = resolution
		for i in 5:
			await process_frame
		var frame: Image = root.get_texture().get_image()
		if frame == null:
			_fail("No renderer texture for book review capture.")
			return false
		if frame.get_size() != resolution:
			frame.resize(resolution.x, resolution.y)
		if frame.save_png(ProjectSettings.globalize_path(OUTPUT + "%s-%dx%d.png" % [prefix, resolution.x, resolution.y])) != OK:
			_fail("Could not save book review capture.")
			return false
	return true


func _tap(code: int) -> void:
	Input.parse_input_event(_key(code))
	await process_frame
	Input.parse_input_event(_release(code))
	await process_frame


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _release(code: int) -> InputEventKey:
	var event := _key(code)
	event.pressed = false
	return event


func _fail(message: String) -> void:
	push_error("HALL_ROUND_BOOK_SMOKE_FAIL: " + message)
	quit(1)
