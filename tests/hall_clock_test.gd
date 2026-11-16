extends "res://tests/support/story_test.gd"
## Step 5: physical hold-to-wind input, partial progress, sound, scene revisit, visual QA.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")


func _run() -> void:
	state.notes.clear()
	state.flags.clear()
	var hall: Node2D = await _new_hall()
	hall.kath.position.x = 760.0
	if not await _capture("interactive-clock-hall-before"):
		return
	hall.kath.position.x = 967.0
	await _tap(KEY_E)
	if hall.mode != &"focus" or not hall.focus.is_open() or hall.kath.controls_enabled:
		_fail("E at the clock did not open the close-up and stop Kath.")
		return
	await create_timer(0.3).timeout
	if hall.focus.selected_action() != &"wind_clock" or hall.ui.journal.visible or hall.ui.pause_menu.visible:
		_fail("The clock focus did not expose its exclusive winding action.")
		return
	if not await _capture("interactive-clock-before"):
		return
	Input.parse_input_event(_key(KEY_E))
	await create_timer(0.38).timeout
	Input.parse_input_event(_release(KEY_E))
	await process_frame
	var held_progress: float = hall.clock_winding_progress
	if held_progress < 0.25 or held_progress > 0.8 or state.has_note(&"clock-housing") or hall.focus.hold_fill.size.x <= 0.0:
		_fail("Releasing E early did not leave visible, incomplete winding progress.")
		return
	if not await _capture("interactive-clock-partial"):
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if hall.mode != &"roam" or state.has_note(&"clock-housing"):
		_fail("Closing a partly wound clock marked the check complete.")
		return
	await _tap(KEY_E)
	await create_timer(0.3).timeout
	if absf(hall.clock_winding_progress - held_progress) > 0.04 or hall.focus.hold_fill.size.x <= 0.0:
		_fail("Reopening the clock lost partial progress.")
		return
	Input.parse_input_event(_key(KEY_E))
	await create_timer(1.05).timeout
	Input.parse_input_event(_release(KEY_E))
	await create_timer(0.35).timeout
	if not bool(state.flags.get("hall_clock_wound", false)) or not state.has_note(&"clock-housing") \
		or state.notes.size() != 1 or not hall.clock_motion.wound or not hall.focus.completed:
		_fail("A full hold did not wind the clock and record the result once.")
		return
	if not await _capture("interactive-clock-after"):
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if hall.mode != &"dialogue":
		_fail("Kath's clock response did not appear after the operation.")
		return
	hall._unhandled_input(_key(KEY_ENTER))
	if hall.mode != &"roam" or hall.clock_tick_audio.stream == null:
		_fail("The steady hall clock did not resume exploration and ticking.")
		return
	hall.kath.position.x = 760.0
	if not await _capture("interactive-clock-hall-after"):
		return
	hall.queue_free()
	await process_frame
	hall = await _new_hall()
	if not hall.clock_motion.wound or hall.clock_winding_progress != 1.0 or state.notes.size() != 1:
		_fail("The clock state was lost after leaving and returning to the hall.")
		return
	hall.kath.position.x = 967.0
	await _tap(KEY_E)
	await create_timer(0.3).timeout
	if not hall.focus.completed or hall.focus.selected_action() != &"":
		_fail("The revisited clock no longer appears wound.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	print("HALL_CLOCK_SMOKE_OK: physical hold, partial resume, completed image, room pendulum, tick, scene revisit")
	hall.queue_free()
	await process_frame
	quit(0)
