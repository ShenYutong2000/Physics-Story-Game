extends SceneTree
## Passenger rope preparation ends with a short empty test, never with Erin boarding.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	_prepare_after_tool_trip(state)
	var shaft = await _open_shaft()
	if shaft == null:
		return
	if shaft.kath.right_limit > 815.0 or shaft.get_node("RopeCore").points.size() != 9:
		_fail("The player crossed the gap or the passenger rope was active too early.")
		return
	shaft._inspect(shaft.rig_inspection)
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("shaft_passenger_rig_inspected", false):
		_fail("Esc committed the spare-pulley inspection.")
		return
	shaft._inspect(shaft.rig_inspection)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._inspect(shaft.long_rope_cabinet)
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_long_rope_taken", false) or shaft.rope_coil.visible:
		_fail("The long rope was not taken from the platform cabinet.")
		return
	shaft._inspect(shaft.rig_inspection)
	if shaft.mode != &"dialogue" or state.flags.get("shaft_passenger_rethread_complete", false):
		_fail("Rethreading was permitted without locking the lower dock.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.lower_dock_latch)
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_lower_dock_locked", false):
		_fail("The lower dock did not support the empty basket.")
		return
	shaft._inspect(shaft.rig_inspection)
	if shaft.mode != &"dialogue":
		_fail("Rethreading was permitted before the top anchor was inspected.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.top_anchor_survey)
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_top_anchor_inspected", false) or not state.has_note(&"shaft-top-anchor"):
		_fail("The top anchor observation was not recorded.")
		return
	shaft._inspect(shaft.rig_inspection)
	if shaft.mode != &"rigging":
		_fail("The prepared rig did not open its threading view.")
		return
	shaft._unhandled_input(_key(KEY_ENTER))
	if shaft.rigging_step != 1 or not shaft.pilot_guide.visible:
		_fail("The pilot line did not show partial threading.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("shaft_passenger_rethread_complete", false) or shaft.get_node("RopeCore").points.size() != 9 or not state.flags.get("shaft_lower_dock_locked", false):
		_fail("Cancelling the threading changed the load-bearing rope or dock.")
		return
	shaft._inspect(shaft.rig_inspection)
	for i in 3:
		shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_passenger_rethread_complete", false) or shaft.get_node("RopeCore").points.size() <= 9 or shaft.pilot_guide.visible or not shaft.rope_mark_near.visible:
		_fail("The two-strand rope path was not completed.")
		return
	if shaft.get_node("RopeCore").points[-1].distance_to(Vector2(1160, 94)) > 0.1:
		_fail("The passenger rope missed the top anchor.")
		return
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._inspect(shaft.winch_console)
	if shaft.mode != &"dialogue":
		_fail("The winch operated while the lower dock was locked.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.lower_dock_latch)
	shaft._unhandled_input(_key(KEY_ENTER))
	if state.flags.get("shaft_lower_dock_locked", true):
		_fail("The lower dock was not released for the empty test.")
		return
	shaft._inspect(shaft.winch_console)
	if shaft.mode != &"winch":
		_fail("The empty-test winch did not open.")
		return
	var mark_before: Vector2 = shaft.rope_mark_near.position
	Input.action_press("move_up")
	shaft._process_winch(3.0)
	Input.action_release("move_up")
	var peak: float = shaft.basket_progress
	if peak < 0.2 or peak > shaft.EMPTY_TEST_LIMIT + 0.001 or float(state.flags.get("shaft_empty_test_peak", 0.0)) < 0.2 or mark_before.distance_to(shaft.rope_mark_near.position) < 10.0:
		_fail("The passenger rig did not make a bounded short lift.")
		return
	shaft._process_winch(0.1)
	if not state.flags.get("shaft_empty_test_held", false) or not is_equal_approx(shaft.basket_progress, peak):
		_fail("Releasing the winch failed to hold the empty basket.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if shaft.mode != &"paused":
		_fail("Pause did not open after the winch view closed.")
		return
	shaft._unhandled_input(_key(KEY_ENTER))
	var count_before: int = state.notes.size()
	shaft._inspect(shaft.return_aperture)
	await process_frame
	if current_scene == shaft:
		_fail("The return passage failed during an empty test.")
		return
	state.travel_to("res://scenes/chapter1_maintenance_shaft.tscn", &"from-inverted-room")
	await process_frame
	shaft = current_scene
	if shaft == null or absf(shaft.basket_progress - peak) > 0.01 or not state.flags.get("shaft_passenger_rethread_complete", false) or state.notes.size() != count_before:
		_fail("The partial test or notes changed across a round trip.")
		return
	shaft._inspect(shaft.winch_console)
	Input.action_press("move_down")
	shaft._process_winch(5.0)
	Input.action_release("move_down")
	if not state.flags.get("shaft_empty_test_complete", false) or shaft.basket_progress > 0.005 or not state.flags.get("shaft_lower_dock_locked", false):
		_fail("The basket did not finish its empty return and lock below.")
		return
	if not state.has_note(&"shaft-empty-passenger-test") or state.notes.size() != count_before + 1 or not shaft.erin.visible or shaft.get_node("BasketRig/ErinInBasket").visible:
		_fail("The conclusion duplicated notes or moved Erin aboard prematurely.")
		return
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._inspect(shaft.winch_console)
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.notes.size() != count_before + 1 or shaft.mode != &"roam":
		_fail("Repeated inspection replayed the test result.")
		return
	current_scene = null
	shaft.queue_free()
	await process_frame
	_prepare_after_tool_trip(state)
	shaft = await _open_shaft()
	if shaft == null:
		return
	shaft._inspect(shaft.lower_dock_latch)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._inspect(shaft.long_rope_cabinet)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._inspect(shaft.top_anchor_survey)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._inspect(shaft.rig_inspection)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_lower_dock_locked", false) or not state.flags.get("shaft_long_rope_taken", false) or not state.flags.get("shaft_top_anchor_inspected", false) or not state.flags.get("shaft_passenger_rig_inspected", false):
		_fail("A different inspection order failed to prepare the same rig.")
		return
	shaft._inspect(shaft.rig_inspection)
	if shaft.mode != &"rigging":
		_fail("A different investigation order did not unlock rethreading.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	current_scene = null
	shaft.queue_free()
	await process_frame
	print("PHASE3_STEP5_SMOKE_OK: dock, guide line, two-strand rig, empty test and persistence")
	quit(0)


func _prepare_after_tool_trip(state: Node) -> void:
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	state.pending_spawn_tag = &""
	state.flags["shaft_rig_inspected"] = true
	state.flags["shaft_erin_contacted"] = true
	state.flags["shaft_tool_goal"] = true
	state.flags["shaft_tools_loaded"] = true
	state.flags["shaft_rail_removed"] = true
	state.flags["shaft_tool_trip_complete"] = true
	state.flags["shaft_basket_progress"] = 0.0


func _open_shaft():
	var shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	return shaft


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_STEP5_SMOKE_FAIL: " + message)
	quit(1)
