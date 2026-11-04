extends SceneTree
## Step 5: physical hold-to-wind input, partial progress, sound, scene revisit, visual QA.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const OUTPUT := "res://prologue-asset-pack-v1/hall-closeups-v2/review-captures/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
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
			_fail("No renderer texture is available for the clock review capture.")
			return false
		if frame.get_size() != resolution:
			frame.resize(resolution.x, resolution.y)
		var filename := OUTPUT + "%s-%dx%d.png" % [prefix, resolution.x, resolution.y]
		if frame.save_png(ProjectSettings.globalize_path(filename)) != OK:
			_fail("Could not save clock review capture: " + filename)
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
	push_error("HALL_CLOCK_SMOKE_FAIL: " + message)
	quit(1)
