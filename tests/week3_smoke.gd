extends SceneTree

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not root.has_node("PrologueState"):
		var test_state := Node.new()
		test_state.name = "PrologueState"
		test_state.set_script(load("res://scripts/prologue_state.gd"))
		root.add_child(test_state)
	var state: Node = root.get_node("PrologueState")
	state.notes.clear()
	state.flags.clear()
	state.pending_spawn_tag = &""
	var hall := HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame

	hall._close_dialogue(false)
	hall._record(&"archive-door")
	hall._record(&"clock-housing")
	hall._record(&"maintenance-sheet")
	if not state.hall_checks_complete() or hall.mode != &"dialogue":
		_fail("Three hall observations did not unlock the machine-room lead.")
		return
	hall._close_dialogue(true)
	hall.kath.position.x = 120.0
	# Physical E traverses the input handler that used to access a null viewport.
	await _tap_key(KEY_E)
	var room := current_scene
	if room == null or room.name != "MachineRoom" or room.kath.position.x != 250.0:
		_fail("Hall exit did not load the Machine Room at its entry point.")
		return
	if room.mode != &"dialogue" or room.kath.controls_enabled:
		_fail("Machine-room entry dialogue did not lock movement.")
		return
	room._close_dialogue(false)
	room.kath.position.x = 120.0
	await _tap_key(KEY_E)
	hall = current_scene
	if hall == null or hall.name != "LibraryHall" or hall.mode != &"dialogue" \
		or not state.flags.get("early_return_cue_seen", false) or state.flags.get("machine_baseline_recorded", false):
		_fail("Returning early did not preserve the unfinished reading and show its reminder.")
		return
	hall._close_dialogue(false)
	await _tap_key(KEY_E)
	room = current_scene
	if room == null or room.name != "MachineRoom" or room.mode != &"roam":
		_fail("Re-entering the Machine Room replayed its introduction or lost the entrance.")
		return
	room.kath.position.x = 1136.0
	room._inspect(room.get_node("Gauge"))
	if room.mode != &"gauge" or not room.ui.gauge_inspection.visible:
		_fail("Gauge comparison view did not open.")
		return
	room._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("machine_baseline_recorded", false) or room.mode != &"roam":
		_fail("Leaving the gauge view with Escape incorrectly recorded a reading.")
		return
	room._inspect(room.get_node("Gauge"))
	room._confirm_gauge_reading()
	if not state.flags.get("machine_baseline_recorded", false) or not state.has_note(&"machine-reading"):
		_fail("Confirmed gauge reading was not recorded.")
		return
	room._close_dialogue(true)
	room._inspect(room.get_node("Gauge"))
	room._confirm_gauge_reading()
	if state.notes.filter(func(note: Dictionary) -> bool: return note["id"] == &"machine-reading").size() != 1:
		_fail("Reopening the gauge duplicated the note.")
		return
	room.kath.position.x = 120.0
	await _tap_key(KEY_E)
	hall = current_scene
	if hall == null or hall.name != "LibraryHall" or hall.kath.position.x != 120.0:
		_fail("Machine-room return did not restore the Hall beside its entrance.")
		return
	if hall.notes.size() != 4 or not state.flags.get("hall_return_cue_seen", false):
		_fail("Hall observations or the one-time return cue were lost.")
		return
	hall._advance_dialogue()
	hall._advance_dialogue()
	hall._unhandled_input(_key(KEY_J))
	if not hall.ui.journal_progress.text.contains("MACHINE ROOM  1 / 1"):
		_fail("Notes did not show separate hall and machine-room progress: " + hall.ui.journal_progress.text)
		return
	hall._unhandled_input(_key(KEY_J))
	await _tap_key(KEY_E)
	room = current_scene
	room.kath.position.x = 861.0
	room._inspect(room.get_node("RouteDiagram"))
	room._advance_dialogue()
	room._advance_dialogue()
	if not state.has_note(&"service-route"):
		_fail("Optional route diagram did not add its observation after dialogue.")
		return
	room._inspect(room.get_node("RouteDiagram"))
	room._advance_dialogue()
	room._advance_dialogue()
	if state.notes.size() != 5:
		_fail("Inspecting the route diagram twice duplicated its observation.")
		return
	room.kath.position.x = 120.0
	await _tap_key(KEY_E)
	hall = current_scene
	if hall.mode != &"roam" or state.notes.size() != 5:
		_fail("A later return replayed the roof leak cue or duplicated observations.")
		return
	print("WEEK3_SMOKE_OK: room travel, early return, cancellable baseline, unique notes, one-time cues")
	hall.get_node("HallAmbience").stop()
	hall.queue_free()
	state.queue_free()
	for i in 4:
		await process_frame
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _tap_key(code: int) -> void:
	Input.parse_input_event(_key(code))
	await process_frame
	var release := _key(code)
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _fail(message: String) -> void:
	push_error("WEEK3_SMOKE_FAIL: " + message)
	quit(1)
