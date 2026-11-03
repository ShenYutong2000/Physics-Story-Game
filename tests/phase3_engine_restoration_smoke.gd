extends SceneTree
## Formal shaft → engine → restored observatory route, cancelled actions and persistent state.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	state.add_note_once(&"castle-on-site-inversion", "Wing inversion", "The wing stopped at the inverted catch.")
	state.flags["shaft_rescue_complete"] = true
	state.flags["shaft_rescue_phase"] = &"rescued"
	state.flags["shaft_lower_dock_locked"] = true
	state.flags["shaft_basket_progress"] = 0.0
	var shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	if shaft.nearest_hotspot(775.0) != shaft.engine_access:
		_fail("The rescued shaft did not expose a reachable engine entry.")
		return
	shaft._inspect(shaft.engine_access)
	await process_frame
	var engine = current_scene
	if engine == null or engine.name != "Chapter1EngineRoom" or engine.kath.position.y != 725.0:
		_fail("The formal engine room did not open at a safe floor position.")
		return
	if engine.drive_isolator_lamp.color.r < 0.8:
		_fail("The Castle feed did not appear connected before isolation.")
		return
	_dismiss(engine)
	engine._inspect(engine.maintenance_drive)
	if engine.mode != &"dialogue":
		_fail("The maintenance drive was usable before inspection.")
		return
	_dismiss(engine)
	engine._inspect(engine.observatory_exit)
	if current_scene != engine:
		_fail("The misaligned observatory passage opened early.")
		return
	_dismiss(engine)
	engine._inspect(engine.obstruction)
	engine._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("engine_jam_seen", false):
		_fail("Esc recorded an unconfirmed observation.")
		return
	var observations: Array[Node] = [engine.stop_indicator, engine.brake_assembly, engine.wall_chart, engine.linkage, engine.obstruction]
	for hotspot in observations:
		engine._inspect(hotspot)
		_dismiss(engine)
	_dismiss(engine)
	if not state.has_note(&"engine-feed-evidence"):
		_fail("The dark home signal did not preserve evidence distinguishing the two drives.")
		return
	if state.flags.get("engine_fault_traced", false):
		_fail("The fault chain was recorded before the player compared its clues.")
		return
	engine._inspect(engine.wall_chart)
	if engine.mode != &"hypothesis":
		_fail("The wall chart did not offer the clue comparison.")
		return
	engine._unhandled_input(_key(KEY_RIGHT))
	engine._unhandled_input(_key(KEY_ENTER))
	_dismiss(engine)
	if state.flags.get("engine_fault_traced", false):
		_fail("The signal-first sequence was accepted despite the mechanical linkage evidence.")
		return
	engine._inspect(engine.wall_chart)
	engine._unhandled_input(_key(KEY_LEFT))
	engine._unhandled_input(_key(KEY_ENTER))
	if engine.mode != &"repair_order":
		_fail("The causal comparison did not lead to a repair-order decision.")
		return
	engine._unhandled_input(_key(KEY_RIGHT))
	engine._unhandled_input(_key(KEY_ENTER))
	_dismiss(engine)
	if state.flags.get("engine_fault_traced", false):
		_fail("Unsafe repair order was accepted.")
		return
	engine._inspect(engine.wall_chart)
	engine._unhandled_input(_key(KEY_LEFT))
	engine._unhandled_input(_key(KEY_ENTER))
	engine._unhandled_input(_key(KEY_LEFT))
	engine._unhandled_input(_key(KEY_ENTER))
	_dismiss(engine)
	if not state.flags.get("engine_fault_traced", false) or not state.has_note(&"engine-fault-chain"):
		_fail("Confirmed clue comparison did not establish the fault chain.")
		return
	engine._inspect(engine.obstruction)
	_dismiss(engine)
	if state.flags.get("engine_jam_cleared", false):
		_fail("The jam was cleared before the automatic drive was isolated.")
		return
	engine._inspect(engine.isolator)
	_dismiss(engine)
	if engine.drive_isolator_lamp.color.r > 0.6:
		_fail("The Castle feed lamp did not change when the drive was isolated.")
		return
	engine._inspect(engine.obstruction)
	_dismiss(engine)
	if not state.flags.get("engine_jam_cleared", false) or engine.jam_debris.visible:
		_fail("The isolated linkage did not clear visually and in shared state.")
		return
	engine._inspect(engine.linkage)
	engine._unhandled_input(_key(KEY_F))
	engine._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("engine_checks_verified", false) or state.has_note(&"engine-home-stop-test"):
		_fail("Cancelling the dry run committed a partial check.")
		return
	engine._inspect(engine.linkage)
	for index in [2, 0, 1]:
		while engine.check_selection != index:
			engine._unhandled_input(_key(KEY_D))
		engine._unhandled_input(_key(KEY_F))
	engine._unhandled_input(_key(KEY_ENTER))
	_dismiss(engine)
	if not state.flags.get("engine_checks_verified", false):
		_fail("The three dry-run checks did not enable the return drive.")
		return
	engine._inspect(engine.maintenance_drive)
	Input.action_press("move_left")
	for i in 25:
		engine._process_return_drive(0.1)
	Input.action_release("move_left")
	engine._unhandled_input(_key(KEY_ESCAPE))
	var held_progress: float = float(state.flags.get("engine_return_progress", 0.0))
	if held_progress <= 0.0 or held_progress >= 1.0 or state.castle_pose != &"inverted":
		_fail("The wing did not stop partway while the shared pose remained inverted.")
		return
	engine._inspect(engine.shaft_return)
	await process_frame
	if current_scene == engine:
		_fail("Kath could not return to the shaft during a paused restoration.")
		return
	shaft = current_scene
	shaft._inspect(shaft.engine_access)
	await process_frame
	engine = current_scene
	if absf(engine.return_progress - held_progress) > 0.001 or engine.window_wing_pivot.rotation >= PI:
		_fail("The wing lost its intermediate position on reentry.")
		return
	engine._inspect(engine.maintenance_drive)
	Input.action_press("move_left")
	for i in 1000:
		if state.castle_pose == &"restored":
			break
		engine._process_return_drive(0.1)
	Input.action_release("move_left")
	if state.castle_pose != &"restored" or not state.has_note(&"engine-wing-restored") or not engine.brake_pawl.visible:
		_fail("The wing did not lock home after controlled return.")
		return
	_dismiss(engine)
	engine._show_journal()
	if not engine.ui.journal_progress.text.contains("ENGINE ROOM  4 / 4") or not engine.ui.journal_progress.text.contains("CASTLE WING  Restored"):
		_fail("The journal did not show the completed repair and restored pose.")
		return
	engine.ui.hide_modals()
	var note_count: int = state.notes.size()
	engine._inspect(engine.observatory_exit)
	await process_frame
	var observatory = current_scene
	if observatory == null or observatory.name != "Chapter1Observatory" or observatory.kath.position.y != 820.0:
		_fail("The restored passage did not open the formal observatory shell.")
		return
	_dismiss(observatory)
	observatory._unhandled_input(_key(KEY_ESCAPE))
	observatory._unhandled_input(_key(KEY_ENTER))
	observatory.kath.position.x = 1490.0
	observatory._process(0.0)
	observatory._unhandled_input(_key(KEY_F))
	await process_frame
	engine = current_scene
	if engine == null or engine.name != "Chapter1EngineRoom" or engine.kath.position.x < 1300.0 or state.notes.size() != note_count:
		_fail("Returning from the observatory changed restoration state or notes.")
		return
	engine._inspect(engine.shaft_return)
	await process_frame
	shaft = current_scene
	shaft._inspect(shaft.return_aperture)
	if current_scene != shaft or shaft.mode != &"dialogue":
		_fail("The old inverted-room hatch stayed traversable after the wing returned home.")
		return
	print("PHASE3_ENGINE_RESTORATION_OK: rescue exit, fault trace, isolation, repair, dry run, slow return, observatory round trip")
	quit(0)


func _dismiss(scene: Node) -> void:
	for i in 6:
		if scene.mode != &"dialogue":
			return
		scene._unhandled_input(_key(KEY_ENTER))


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_ENGINE_RESTORATION_FAIL: " + message)
	quit(1)
