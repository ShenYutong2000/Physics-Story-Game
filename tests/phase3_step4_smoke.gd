extends SceneTree
## Rescue survey, safe loading, hand winch, handoff and persistent return.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	state.pending_spawn_tag = &""
	var shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	if shaft.kath.right_limit > 815.0 or shaft.get_node("BasketRig/ToolCrate").visible:
		_fail("The player crossed the gap or the basket began loaded.")
		return
	shaft._inspect(shaft.rig_inspection)
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("shaft_rig_inspected", false) or state.has_note(&"shaft-direct-rope"):
		_fail("Esc committed a cancelled rig inspection.")
		return
	shaft._inspect(shaft.rig_inspection)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_tool_goal", false) or shaft.mode != &"dialogue":
		_fail("Either investigation order should produce the tool objective.")
		return
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.has_note(&"shaft-erin-rail") or not state.has_note(&"shaft-direct-rope"):
		_fail("The two confirmed observations are absent from the notes.")
		return
	shaft._inspect(shaft.tool_chest)
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("shaft_tools_loaded", false):
		_fail("Esc loaded the tool chest.")
		return
	shaft._inspect(shaft.tool_chest)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	await create_timer(2.1).timeout
	if not state.flags.get("shaft_tools_loaded", false) or not shaft.basket_tools.visible or shaft.platform_tools.visible or shaft.transfer_tools.visible or absf(shaft.loading_spur.scale.x - 0.11) > 0.001:
		_fail("The loading tray did not transfer the tools into the basket.")
		return
	shaft._inspect(shaft.winch_console)
	if shaft.mode != &"winch":
		_fail("The loaded basket did not unlock the hand winch.")
		return
	Input.action_press("move_up")
	shaft._process_winch(2.5)
	if shaft.brake_lever.rotation >= -0.1:
		_fail("The winch brake lever did not respond to cranking.")
		return
	Input.action_release("move_up")
	var midway: float = shaft.basket_progress
	if midway < 0.4 or midway > 0.6:
		_fail("The winch did not move the basket gradually.")
		return
	shaft._process_winch(1.0)
	if not is_equal_approx(shaft.basket_progress, midway) or absf(shaft.brake_lever.rotation) > 0.001:
		_fail("Releasing the winch control did not hold the basket.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._process(0.5)
	if shaft.mode != &"paused" or not is_equal_approx(shaft.basket_progress, midway):
		_fail("Pausing during a partial lift changed the basket height.")
		return
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_J))
	if shaft.mode != &"journal":
		_fail("The journal did not open after the winch view closed.")
		return
	shaft._unhandled_input(_key(KEY_J))
	shaft.kath.position.x = 190.0
	shaft._unhandled_input(_key(KEY_E))
	await process_frame
	if current_scene == shaft:
		_fail("The shaft return route failed during a partial lift.")
		return
	state.travel_to("res://scenes/chapter1_maintenance_shaft.tscn", &"from-inverted-room")
	await process_frame
	shaft = current_scene
	if shaft == null or shaft.name != "Chapter1MaintenanceShaft" or absf(shaft.basket_progress - midway) > 0.01:
		_fail("A shaft round trip did not restore the basket height.")
		return
	var note_count: int = state.notes.size()
	shaft._inspect(shaft.winch_console)
	Input.action_press("move_up")
	shaft._process_winch(10.0)
	Input.action_release("move_up")
	if shaft.basket_progress > 1.0 or shaft.basket_progress < 0.995:
		_fail("The raised basket missed the upper limit.")
		return
	shaft._unhandled_input(_key(KEY_E))
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("shaft_rail_removed", false):
		_fail("Cancelling the handoff removed Erin's rail.")
		return
	shaft._inspect(shaft.winch_console)
	shaft._unhandled_input(_key(KEY_E))
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_rail_removed", false) or shaft.bent_rail.visible or not shaft.open_rail.visible:
		_fail("Erin's repair did not change the rail state.")
		return
	shaft._inspect(shaft.winch_console)
	Input.action_press("move_down")
	shaft._process_winch(10.0)
	Input.action_release("move_down")
	if shaft.basket_progress > 0.005 or shaft.basket_tools.visible:
		_fail("The empty basket did not return to the lower berth.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.winch_console)
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.has_note(&"shaft-tool-trip"):
		_fail("Esc committed the conclusion note.")
		return
	shaft._inspect(shaft.winch_console)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_tool_trip_complete", false) or not state.has_note(&"shaft-tool-trip") or state.notes.size() != note_count + 1:
		_fail("The completed tool trip was not recorded exactly once.")
		return
	shaft._inspect(shaft.winch_console)
	if state.notes.size() != note_count + 1 or shaft.get_node("RopeCore").points.size() != 9 or state.flags.get("shaft_passenger_rethread_complete", false):
		_fail("Repeat interaction duplicated notes or enabled the passenger rope before rethreading.")
		return
	shaft._close_overlay()
	current_scene = null
	shaft.queue_free()
	await process_frame
	state.flags.clear()
	state.notes.clear()
	state.pending_spawn_tag = &""
	shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._inspect(shaft.rig_inspection)
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_tool_goal", false):
		_fail("Inspecting Erin before the rope did not unlock the same objective.")
		return
	shaft._close_overlay()
	current_scene = null
	shaft.queue_free()
	await process_frame
	print("PHASE3_STEP4_SMOKE_OK: inspection, loading, controlled lift, repair, return and persistence")
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_STEP4_SMOKE_FAIL: " + message)
	quit(1)
