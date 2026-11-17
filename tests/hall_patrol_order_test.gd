extends "res://tests/support/story_test.gd"
## Step 10: every patrol order, both latch orders, modal interruptions, and the machine-room handoff.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const ORDERS := [
	["fixtures", "clock", "keys"], ["fixtures", "keys", "clock"],
	["clock", "fixtures", "keys"], ["clock", "keys", "fixtures"],
	["keys", "fixtures", "clock"], ["keys", "clock", "fixtures"],
]


func _run() -> void:
	state.persistence_enabled = false
	for fixtures_first in [true, false]:
		for order in ORDERS:
			state.flags.clear()
			state.notes.clear()
			state.pending_spawn_tag = &""
			var hall: Node2D = await _new_hall()
			var expected_ids: Array[StringName] = []
			if not await _check_modal_interruptions(hall, state):
				return
			for task in order:
				match task:
					"fixtures":
						if not await _do_fixtures(hall, state, fixtures_first):
							return
						expected_ids.append(&"archive-door")
					"clock":
						if not await _do_clock(hall, state):
							return
						expected_ids.append(&"clock-housing")
					"keys":
						if not await _do_keys(hall, state):
							return
						expected_ids.append(&"duty-keys")
				if state.hall_checks_complete() or not _main_notes_match(state, expected_ids):
					_fail("Task order %s / fixtures first %s produced a premature gate or wrong note order." % [order, fixtures_first])
					return
			if not await _file_round(hall, state):
				return
			if not state.hall_checks_complete() or not _main_notes_match(state, expected_ids):
				_fail("A filed patrol lost its original discovery order.")
				return
			if not await _check_revisit(hall, state):
				return
			if fixtures_first == true and order == ORDERS[0]:
				hall.kath.position.x = 760.0
				if not await _capture("step10-patrol-complete"):
					return
				hall.kath.position.x = 120.0
				hall._inspect(hall.archive_door)
				await process_frame
				var machine: Node = current_scene
				if machine == hall or machine.name != "MachineRoom" or state.weather_phase() != &"rain":
					_fail("The filed archive door did not enter the rainy machine room.")
					return
				if not await _capture("step10-machine-entry"):
					return
				machine.queue_free()
			else:
				hall.queue_free()
			await process_frame
	print("HALL_PERMUTATION_PLAYTHROUGH_OK: 12 task paths, cancellation, pause, journal, repeat, filing, revisit, machine entry")
	quit(0)


func _check_modal_interruptions(hall: Node2D, state: Node) -> bool:
	hall.kath.position.x = 476.0
	hall._unhandled_input(_key(KEY_ESCAPE))
	if hall.mode != &"paused" or hall.kath.controls_enabled:
		_fail("Esc in the hall did not pause movement.")
		return false
	hall._unhandled_input(_key(KEY_E))
	if hall.mode != &"paused":
		_fail("E opened a hotspot through pause.")
		return false
	hall._unhandled_input(_key(KEY_ENTER))
	hall._unhandled_input(_key(KEY_J))
	if hall.mode != &"journal" or not hall.ui.journal.visible:
		_fail("The empty journal could not be opened after pause.")
		return false
	hall._unhandled_input(_key(KEY_ESCAPE))
	if hall.mode != &"roam":
		_fail("Esc did not return from the journal to exploration.")
		return false
	hall._inspect(hall.high_window)
	await create_timer(FOCUS_IN).timeout
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode != &"roam" or state.flags.get("hall_window_fixed", false):
		_fail("Esc on an untouched window changed the fixture state.")
		return false
	return true


func _do_fixtures(hall: Node2D, state: Node, door_first: bool) -> bool:
	var parts := [hall.archive_door, hall.high_window] if door_first else [hall.high_window, hall.archive_door]
	for part in parts:
		hall._inspect(part)
		await create_timer(FOCUS_IN).timeout
		if hall.mode != &"focus" or hall.ui.journal.visible or hall.ui.pause_menu.visible:
			_fail("Door/window close-up overlapped another modal.")
			return false
		if part == hall.archive_door:
			await _hold_on(hall, KEY_E, SLIDE_HOLD)
		else:
			hall._unhandled_input(_key(KEY_E))
		if part == parts[0] and state.has_note(&"archive-door"):
			_fail("The combined fixture check was recorded after only one latch.")
			return false
		hall._unhandled_input(_key(KEY_ESCAPE))
		await create_timer(FOCUS_OUT).timeout
		if hall.mode == &"dialogue":
			hall._unhandled_input(_key(KEY_ENTER))
	if not state.has_note(&"archive-door") or not hall.door_bolt_world.secured or not hall.window_catch_world.secured:
		_fail("Both fixtures did not complete the single check and world props.")
		return false
	return true


func _do_clock(hall: Node2D, state: Node) -> bool:
	hall._inspect(hall.get_node("OldClock"))
	await create_timer(FOCUS_IN).timeout
	Input.parse_input_event(_key(KEY_E))
	await create_timer(1.1).timeout
	Input.parse_input_event(_release(KEY_E))
	await create_timer(FOCUS_IN).timeout
	if not state.has_note(&"clock-housing") or not hall.clock_motion.wound:
		_fail("Holding E did not wind the clock.")
		return false
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode == &"dialogue":
		hall._unhandled_input(_key(KEY_ENTER))
	return true


func _do_keys(hall: Node2D, state: Node) -> bool:
	hall._inspect(hall.get_node("DutyKeys"))
	await create_timer(FOCUS_IN).timeout
	hall._unhandled_input(_key(KEY_E))
	await create_timer(0.55).timeout
	if not state.has_note(&"duty-keys") or not hall.key_rack_world.east_key_sorted:
		_fail("E did not move the east-service key in both views.")
		return false
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode == &"dialogue":
		hall._unhandled_input(_key(KEY_ENTER))
	return true


func _file_round(hall: Node2D, state: Node) -> bool:
	hall._inspect(hall.get_node("MaintenanceSheet"))
	await create_timer(FOCUS_IN).timeout
	if hall.mode != &"round_book" or not hall.round_book.tasks.all(func(done: bool) -> bool: return done):
		_fail("The completed checklist did not show three live checks.")
		return false
	hall._unhandled_input(_key(KEY_E))
	await create_timer(1.05).timeout
	if not state.flags.get("hall_round_filed", false) or not hall.round_book_world.filed:
		_fail("The completed round did not file after stamping.")
		return false
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode == &"dialogue":
		hall._unhandled_input(_key(KEY_ENTER))
	return true


func _check_revisit(hall: Node2D, state: Node) -> bool:
	var note_count: int = state.notes.size()
	for part in [hall.high_window, hall.get_node("OldClock"), hall.get_node("DutyKeys")]:
		hall._inspect(part)
		await create_timer(FOCUS_IN).timeout
		if not hall.focus.completed:
			_fail("A completed prop reopened in its initial state.")
			return false
		hall._unhandled_input(_key(KEY_E))
		hall._unhandled_input(_key(KEY_ESCAPE))
		await create_timer(FOCUS_OUT).timeout
		if hall.mode == &"dialogue":
			hall._unhandled_input(_key(KEY_ENTER))
	if state.notes.size() != note_count:
		_fail("Repeating a completed prop duplicated a note.")
		return false
	return true


func _main_notes_match(state: Node, expected: Array[StringName]) -> bool:
	var actual: Array[StringName] = []
	for entry in state.notes:
		if entry["id"] in state.HALL_NOTE_IDS:
			actual.append(entry["id"])
	return actual == expected
