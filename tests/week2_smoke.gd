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
	var hall: Node2D = HALL.instantiate()
	root.add_child(hall)
	await process_frame
	var kath: CharacterBody2D = hall.get_node("Kath")
	var ui: CanvasLayer = hall.get_node("HallUI")
	var wick: Node2D = hall.get_node("Wick")

	if hall.mode != &"dialogue" or kath.controls_enabled or not ui.dialogue.visible:
		_fail("Opening dialogue did not lock movement.")
		return
	await _tap_key(KEY_ENTER)
	if hall.mode != &"roam" or not kath.controls_enabled:
		_fail("The physical Enter binding did not close the opening dialogue.")
		return
	if InputMap.action_get_events("interact").is_empty() or InputMap.action_get_events("toggle_journal").is_empty():
		_fail("Week 2 input actions are missing.")
		return
	if hall.nearest_hotspot(760.0) != null or hall.nearest_hotspot(80.0).interaction_id != &"archive-door":
		_fail("Door reach or distant interaction is wrong.")
		return
	await _tap_key(KEY_E)
	if hall.mode != &"roam":
		_fail("A physical distant E press opened an inspection.")
		return
	if hall.nearest_hotspot(1080.0).interaction_id != &"clock-housing" \
		or hall.nearest_hotspot(1100.0).interaction_id != &"maintenance-sheet":
		_fail("Overlapping hotspots did not choose the nearest approach point.")
		return
	kath.position.x = 120.0
	await process_frame
	if not ui.prompt.visible or ui.layer <= 0:
		_fail("The reachable door has no foreground-safe E prompt.")
		return
	kath.position.x = 760.0
	Input.action_press("move_right")
	for i in 12:
		await physics_frame
	Input.action_release("move_right")
	if not wick.flying:
		_fail("Wick did not fly while Kath moved.")
		return
	for i in 22:
		await physics_frame
	if wick.flying:
		_fail("Wick did not settle after Kath stopped.")
		return

	# The journal opens empty and every modal stops Kath.
	hall._unhandled_input(_key(KEY_J))
	if hall.mode != &"journal" or hall.notes.size() != 0 or kath.controls_enabled:
		_fail("Empty journal failed.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	if hall.mode != &"roam":
		_fail("Escape did not close the journal.")
		return

	# Inspect the sheet first: closes into Kath's response, then saves one note.
	kath.position.x = 1212.0
	await _tap_key(KEY_E)
	if hall.mode != &"inspection" or not ui.sheet.visible or kath.controls_enabled:
		_fail("The readable sheet view did not open exclusively.")
		return
	hall._unhandled_input(_key(KEY_J))
	if hall.mode != &"inspection" or ui.journal.visible:
		_fail("Notes opened over the sheet.")
		return
	hall._close_sheet()
	if hall.notes.size() != 1:
		_fail("Closing the sheet did not immediately record its observation.")
		return
	hall._advance_dialogue()
	if hall.notes.size() != 1 or hall.notes[0]["id"] != &"maintenance-sheet" or not ui.hint.visible:
		_fail("The first observation or J hint was not recorded.")
		return
	hall._unhandled_input(_key(KEY_J))
	if hall.mode != &"journal" or not ui.journal_entries.text.contains("Maintenance sheet"):
		_fail("The first note did not appear in the journal.")
		return
	hall._unhandled_input(_key(KEY_J))
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	hall._close_sheet()
	hall._advance_dialogue()
	if hall.notes.size() != 1:
		_fail("Repeating a sheet inspection duplicated its note.")
		return

	kath.position.x = 967.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	await process_frame
	if not wick.flying or wick.reaction_time <= 0.0:
		_fail("Wick did not react to the clock.")
		return
	hall._advance_dialogue()
	hall._advance_dialogue()
	if hall.notes.size() != 2 or hall.notes[1]["id"] != &"clock-housing":
		_fail("Clock observation was not appended in discovery order.")
		return

	kath.position.x = 120.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	hall._advance_dialogue()
	hall._advance_dialogue()
	if hall.notes.size() != 3 or hall.notes[2]["id"] != &"archive-door" \
		or not hall.completion_played or hall.mode != &"dialogue":
		_fail("Three inspections did not trigger the final line exactly once.")
		return
	hall._advance_dialogue()
	kath.position.x = 967.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	hall._advance_dialogue()
	hall._advance_dialogue()
	if hall.notes.size() != 3 or hall.mode != &"roam":
		_fail("Repeating the final inspection replayed completion or duplicated notes.")
		return

	hall._unhandled_input(_key(KEY_ESCAPE))
	if hall.mode != &"paused" or not ui.pause_menu.visible or kath.controls_enabled:
		_fail("Pause mode failed.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	if hall.mode != &"roam" or not kath.controls_enabled:
		_fail("Pause did not resume exploration.")
		return
	var held_e := _key(KEY_E)
	held_e.echo = true
	hall._unhandled_input(held_e)
	if hall.mode != &"roam":
		_fail("A held E reopened an inspection after closing a modal.")
		return
	print("WEEK2_SMOKE_OK: reach, nearest, modals, notes, Wick, completion, pause")
	hall.queue_free()
	root.get_node("PrologueState").queue_free()
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
	push_error("WEEK2_SMOKE_FAIL: " + message)
	quit(1)
