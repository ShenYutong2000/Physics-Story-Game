extends "res://tests/support/story_test.gd"
## Optional hall discoveries: cancel, visible action, repeat, persistence, no patrol credit.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _run() -> void:
	state.persistence_enabled = false
	state.notes.clear()
	state.flags.clear()
	var hall: Node2D = await _new_hall()
	hall.kath.position.x = 800.0
	if not await _capture("optional-hall-before"):
		return
	for item in [
		{"x": 216.0, "action": &"wipe_plaque", "flag": "hall_plaque_cleaned", "note": &"old-plaque", "capture": "optional-plaque"},
		{"x": 1054.0, "action": &"open_clock_cover", "flag": "hall_clock_cover_open", "note": &"clock-inner-cover", "capture": "optional-clock-cover"},
		{"x": 1114.0, "action": &"flip_catalogue", "flag": "hall_catalogue_flipped", "note": &"catalogue-card", "capture": "optional-catalogue"},
	]:
		hall.kath.position.x = item.x
		await _tap(KEY_E)
		await create_timer(0.28).timeout
		if hall.mode != &"focus" or hall.focus.selected_action() != item.action or hall.kath.controls_enabled:
			_fail("Optional focus unavailable: " + item.capture)
			return
		if not await _capture(item.capture + "-before"):
			return
		await _dismiss(hall)
		if state.flags.get(item.flag, false) or state.has_note(item.note):
			_fail("Cancel recorded optional action: " + item.capture)
			return
		await _tap(KEY_E)
		await create_timer(0.28).timeout
		await _tap(KEY_E)
		await create_timer(0.55).timeout
		if not state.flags.get(item.flag, false) or not state.has_note(item.note) or not hall.focus.completed:
			_fail("Optional action did not persist: " + item.capture)
			return
		if item.note == &"old-plaque" and hall.focus.inscription_label.text != "GRAND\nARCHIVE":
			_fail("Cleaned plaque did not show its name on the object.")
			return
		if item.note == &"catalogue-card" and (not hall.catalogue_card_world.flipped or not hall.focus.inscription_label.text.contains("MOTION")):
			_fail("Catalogue card did not turn and reveal the former headings.")
			return
		if not await _capture(item.capture + "-after"):
			return
		await _dismiss(hall)
		await _tap(KEY_E)
		await create_timer(0.28).timeout
		if not hall.focus.completed or hall.focus.selected_action() != &"":
			_fail("Reopening changed completed optional state: " + item.capture)
			return
		await _tap(KEY_E)
		if state.notes.size() > 3:
			_fail("Repeated E duplicated an optional note.")
			return
		await _dismiss(hall)
	if state.notes.size() != 3 or state.hall_checks_complete() or state.has_note(&"archive-door") or state.has_note(&"clock-housing") or state.has_note(&"duty-keys"):
		_fail("Optional discoveries changed main patrol progress.")
		return
	hall.kath.position.x = 800.0
	if not await _capture("optional-hall-after"):
		return
	for detail in [
		{"x": 120.0, "subject": &"door", "action": &"secure_door_bolt"},
		{"x": 967.0, "subject": &"clock", "action": &"wind_clock"},
	]:
		hall.kath.position.x = detail.x
		await _tap(KEY_E)
		await create_timer(0.28).timeout
		if hall.focus_subject != detail.subject or hall.focus_part != 0 or hall.focus.selected_action() != detail.action:
			_fail("The main prop focus no longer opens correctly.")
			return
		await _tap(KEY_RIGHT)
		await create_timer(0.28).timeout
		if hall.focus_part != 1 or not hall.focus.completed:
			_fail("Right arrow did not reveal the optional detail.")
			return
		await _tap(KEY_LEFT)
		await create_timer(0.28).timeout
		if hall.focus_part != 0 or hall.focus.selected_action() != detail.action:
			_fail("Left arrow did not return to the main control.")
			return
		await _dismiss(hall)
	hall.queue_free()
	await process_frame
	hall = await _new_hall()
	if not hall.catalogue_card_world.flipped or not hall.plaque_world.revealed or not hall.clock_cover_world.revealed or state.notes.size() != 3:
		_fail("Returning to the hall reset optional state.")
		return
	hall.kath.position.x = 216.0
	await _tap(KEY_E)
	await create_timer(0.28).timeout
	if not hall.focus.completed or hall.focus.inscription_label.text != "GRAND\nARCHIVE":
		_fail("Returning to the hall hid the cleaned nameplate.")
		return
	await _dismiss(hall)
	for note_id in state.HALL_NOTE_IDS:
		state.add_note_once(note_id, "Patrol", "Completed")
	state.flags["hall_round_filed"] = true
	if not state.hall_checks_complete():
		_fail("Test setup did not file the hall round.")
		return
	hall.kath.position.x = 216.0
	await _tap(KEY_E)
	await create_timer(0.28).timeout
	if hall.mode != &"focus" or hall.focus_part != 1:
		_fail("The optional plaque became inaccessible after the machine-room exit opened.")
		return
	print("HALL_OPTIONAL_SMOKE_OK: cancel, visible actions, repeat, revisit, patrol isolation, two resolutions")
	quit(0)


func _dismiss(hall: Node2D) -> void:
	await _tap(KEY_ESCAPE)
	await create_timer(0.22).timeout
	if hall.mode == &"dialogue":
		hall._close_dialogue(false)
