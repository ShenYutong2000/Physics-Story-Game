extends SceneTree
## Two-resolution review frames for the formal fifth step.

const ENGINE: PackedScene = preload("res://scenes/chapter1_engine_room.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-engine-restoration"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	state.flags["shaft_rescue_complete"] = true
	var engine = ENGINE.instantiate()
	root.add_child(engine)
	current_scene = engine
	await process_frame
	engine.kath.position.x = 760.0
	if not await _capture_pair("01-jammed-engine"):
		quit(1)
		return
	for flag in engine.OBSERVATION_FLAGS:
		state.flags[flag] = true
	state.flags["engine_fault_traced"] = true
	state.flags["engine_drive_isolated"] = true
	state.flags["engine_jam_cleared"] = true
	engine._refresh_art()
	engine.kath.position.x = 940.0
	engine._start_verification()
	engine.pending_checks.append(&"stop")
	engine.pending_checks.append(&"brake")
	engine.check_selection = 2
	engine._update_check_panel()
	if not await _capture_pair("02-home-stop-dry-run"):
		quit(1)
		return
	engine._close_overlay()
	state.flags["engine_checks_verified"] = true
	engine.return_progress = 0.53
	state.flags["engine_return_progress"] = 0.53
	engine._refresh_art()
	engine.kath.position.x = 1275.0
	engine._open_drive()
	if not await _capture_pair("03-slow-return"):
		quit(1)
		return
	engine._close_overlay()
	state.castle_pose = &"restored"
	state.flags["engine_restored"] = true
	engine.return_progress = 1.0
	engine._refresh_art()
	if not await _capture_pair("04-home-locked"):
		quit(1)
		return
	state.travel_to("res://scenes/chapter1_observatory.tscn", &"from-engine-room")
	await process_frame
	var observatory = current_scene
	if observatory.mode == &"dialogue":
		observatory._unhandled_input(_key(KEY_ENTER))
	if not await _capture_pair("05-observatory-entry"):
		quit(1)
		return
	print("PHASE3_ENGINE_RESTORATION_CAPTURE_OK: five scene states at both resolutions")
	quit(0)


func _capture_pair(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		root.size = resolution
		for i in 5:
			await process_frame
		var frame: Image = root.get_texture().get_image()
		var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
		DirAccess.make_dir_recursive_absolute(folder)
		var name := "%s-%dx%d.png" % [prefix, resolution.x, resolution.y]
		if frame.save_png(folder.path_join(name)) != OK:
			push_error("Could not save " + name)
			return false
	return true


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event
