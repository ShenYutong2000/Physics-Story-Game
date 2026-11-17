extends "res://tests/support/story_test.gd"

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _run() -> void:
	if not root.has_node("PrologueState"):
		var test_state := Node.new()
		test_state.name = "PrologueState"
		test_state.set_script(load("res://scripts/prologue_state.gd"))
		root.add_child(test_state)
	var hall: Node2D = HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	# Normal change_scene_to_file emits scene_changed after the hall's _ready() sets the intro.
	root.get_node("GameSettings")._on_scene_changed(hall)
	var kath: CharacterBody2D = hall.get_node("Kath")
	var ui: CanvasLayer = hall.get_node("HallUI")
	var wick: Node2D = hall.get_node("Wick")

	if hall.mode != &"roam" or not kath.controls_enabled or ui.dialogue.visible or ui.caption_panel.visible:
		_fail("Kath could not move at once on entering the hall.")
		return
	await create_timer(1.2).timeout
	if hall.mode != &"roam" or not kath.controls_enabled or not ui.caption_panel.visible or ui.caption_text.text != "Evening again. The light leaves the hall so quietly.":
		_fail("Kath's first thought did not arrive as a caption that leaves her free to move.")
		return
	ui.hide_caption()
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
	if hall.nearest_hotspot(967.0).interaction_id != &"clock-housing" \
		or hall.nearest_hotspot(1080.0).interaction_id != &"clock-inner-cover" \
		or hall.nearest_hotspot(1100.0).interaction_id != &"catalogue-card" \
		or hall.nearest_hotspot(1212.0).interaction_id != &"maintenance-sheet":
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
	if hall.mode != &"journal" or state.notes.size() != 0 or kath.controls_enabled:
		_fail("Empty journal failed.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	if hall.mode != &"roam":
		_fail("Escape did not close the journal.")
		return

	# The emergency page can be read before any checks and re-read without another note.
	kath.position.x = 1212.0
	await _tap_key(KEY_E)
	if hall.mode != &"round_book" or not hall.round_book.screen.visible or kath.controls_enabled:
		_fail("The round book did not open exclusively.")
		return
	hall._unhandled_input(_key(KEY_J))
	if hall.mode != &"round_book" or ui.journal.visible:
		_fail("Notes opened over the round book.")
		return
	hall._unhandled_input(_key(KEY_RIGHT))
	if state.notes.size() != 1 or state.notes[0]["id"] != &"emergency-procedure":
		_fail("The early emergency page was not recorded once.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	hall._unhandled_input(_key(KEY_J))
	if hall.mode != &"journal" or not ui.journal_entries.text.contains("Emergency page"):
		_fail("The first note did not appear in the journal.")
		return
	hall._unhandled_input(_key(KEY_J))
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	hall._unhandled_input(_key(KEY_RIGHT))
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if state.notes.size() != 1:
		_fail("Repeating the red-tab inspection duplicated its note.")
		return

	kath.position.x = 967.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	await process_frame
	if not wick.flying or wick.reaction_time <= 0.0:
		_fail("Wick did not react to the clock.")
		return
	await create_timer(FOCUS_IN).timeout
	hall._unhandled_input(_key(KEY_E))
	hall._process(0.55)
	var released_e := _key(KEY_E)
	released_e.pressed = false
	hall._unhandled_input(released_e)
	if state.notes.size() != 1 or hall.clock_winding_progress < 0.5:
		_fail("Releasing E early did not preserve partial winding without recording the clock.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	await create_timer(FOCUS_IN).timeout
	hall._unhandled_input(_key(KEY_E))
	hall._process(0.5)
	hall._unhandled_input(released_e)
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	hall._advance_dialogue()
	if state.notes.size() != 2 or state.notes[1]["id"] != &"clock-housing":
		_fail("The completed clock winding was not appended in discovery order.")
		return

	kath.position.x = 120.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	if hall.mode != &"focus" or not hall.focus.is_open():
		_fail("The archive door did not open its playable close-up.")
		return
	await create_timer(FOCUS_IN).timeout
	hall._secure_door_bolt()
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode != &"roam" or ui.caption_text.text != "That should hold. The wind loves finding little gaps.":
		_fail("Completing and leaving the door close-up did not leave Kath free with her line.")
		return
	if state.notes.size() != 2 or hall.mode != &"roam":
		_fail("The door alone should not complete the combined door-and-window check.")
		return
	kath.position.x = 476.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	await create_timer(FOCUS_IN).timeout
	hall._fix_window_catch()
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	hall._advance_dialogue()
	if state.notes.size() != 3 or state.notes[2]["id"] != &"archive-door" \
		or hall.completion_played or hall.mode != &"roam":
		_fail("The door-and-window check should wait for the duty keys and filing.")
		return
	kath.position.x = 1370.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	await create_timer(FOCUS_IN).timeout
	hall._sort_duty_key()
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	hall._advance_dialogue()
	if state.notes.size() != 4 or state.notes[3]["id"] != &"duty-keys" or hall.completion_played:
		_fail("Sorting the duty keys did not leave the stamp as the final action.")
		return
	kath.position.x = 1212.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	hall._unhandled_input(_key(KEY_E))
	await create_timer(1.2).timeout
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if state.notes.size() != 5 or state.notes[4]["id"] != &"evening-round-filed" \
		or not hall.completion_played or hall.mode != &"dialogue":
		_fail("Filing the completed round did not trigger the final line once.")
		return
	hall._advance_dialogue()
	kath.position.x = 967.0
	hall._inspect(hall.nearest_hotspot(kath.position.x))
	await create_timer(FOCUS_IN).timeout
	if not hall.focus.completed:
		_fail("The wound clock did not reopen in its completed state.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if state.notes.size() != 5 or hall.mode != &"roam":
		_fail("Repeating the final inspection replayed completion or duplicated notes (mode=%s, notes=%d)." % [hall.mode, state.notes.size()])
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


func _tap_key(code: int) -> void:
	Input.parse_input_event(_key(code))
	await process_frame
	var release := _key(code)
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
