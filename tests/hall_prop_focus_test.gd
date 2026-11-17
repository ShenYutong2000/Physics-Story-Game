extends "res://tests/support/story_test.gd"
## Steps 3–4: exercise playable hall close-ups and save review frames.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _run() -> void:
	state.notes.clear()
	state.flags.clear()
	var hall: Node2D = HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	hall._unhandled_input(_key(KEY_ENTER))
	var kath: CharacterBody2D = hall.get_node("Kath")
	var ui: CanvasLayer = hall.get_node("HallUI")
	var focus: CanvasLayer = hall.get_node("HallPropFocus")
	if not await _capture("interactive-hall-before"):
		return
	kath.position.x = 120.0
	await _tap(KEY_E)
	if hall.mode != &"focus" or not focus.is_open() or kath.controls_enabled or state.has_note(&"archive-door"):
		_fail("Opening E should show the close-up without operating the door.")
		return
	await create_timer(FOCUS_IN).timeout
	if focus.selected_action() != &"secure_door_bolt" or ui.journal.visible or ui.pause_menu.visible:
		_fail("The door action or modal ownership is incorrect.")
		return
	if not await _capture("interactive-door-before"):
		return
	hall._unhandled_input(_key(KEY_J))
	if hall.mode != &"focus" or ui.journal.visible:
		_fail("J opened the journal over the prop close-up.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode != &"roam" or state.has_note(&"archive-door") or bool(state.flags.get("hall_door_latched", false)):
		_fail("Esc from an untouched close-up wrote progress or kept Kath locked.")
		return
	await _tap(KEY_E)
	await create_timer(FOCUS_IN).timeout
	await _tap(KEY_E)
	if bool(state.flags.get("hall_door_latched", false)) or focus.gesture.progress != 0.0:
		_fail("A single tap should only strain the stiff bolt, not move or latch it.")
		return
	await _hold_on(hall, KEY_E, SLIDE_HOLD)
	if not bool(state.flags.get("hall_door_latched", false)) or state.has_note(&"archive-door") or not focus.completed:
		_fail("Operating the door should change its state without completing the combined check.")
		return
	await create_timer(0.33).timeout
	if not await _capture("interactive-door-after"):
		return
	await _tap(KEY_E)
	if state.notes.size() != 0:
		_fail("Repeated door operation wrote a premature note.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if focus.is_open() or not ui.caption_panel.visible or ui.caption_text.text != "That should hold. The wind loves finding little gaps.":
		_fail("Kath's line did not follow the latched door as a caption.")
		return
	if hall.mode != &"roam":
		_fail("The response did not return to exploration.")
		return
	await _tap(KEY_E)
	await create_timer(FOCUS_IN).timeout
	if not focus.completed or focus.selected_action() != &"" or state.notes.size() != 0:
		_fail("Reopening did not restore the secured state.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode != &"roam" or ui.journal.visible or ui.pause_menu.visible:
		_fail("Returning from a repeat visit left an overlapping modal.")
		return
	kath.position.x = 476.0
	await _tap(KEY_E)
	await create_timer(FOCUS_IN).timeout
	if focus.selected_action() != &"fix_window_catch":
		_fail("The window close-up did not expose its catch action.")
		return
	if not await _capture("interactive-window-before"):
		return
	await _tap(KEY_E)
	await create_timer(FOCUS_IN).timeout
	if not bool(state.flags.get("hall_window_fixed", false)) or not state.has_note(&"archive-door") or state.notes.size() != 1:
		_fail("The second latch did not complete exactly one combined check.")
		return
	if not await _capture("interactive-window-after"):
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	hall._unhandled_input(_key(KEY_ENTER))
	await _tap(KEY_E)
	await create_timer(FOCUS_IN).timeout
	if not focus.completed or state.notes.size() != 1:
		_fail("Window state did not persist on revisit.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	kath.position.x = 760.0
	if not await _capture("interactive-hall-after"):
		return
	print("HALL_FOCUS_SMOKE_OK: door and window, cancel, combined check, revisit, modal isolation, both review sizes")
	hall.queue_free()
	await process_frame
	quit(0)
