extends SceneTree
## On-site return test: observed setup, one continuous inversion, persistent aftermath.

const CONTROL: PackedScene = preload("res://scenes/castle_control_walkway.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.flags["incident_complete"] = true
	state.flags["control_walkway_intro_seen"] = true
	state.flags["service_road_intro_seen"] = true
	state.flags["service_gate_open"] = true
	if not state.transition_castle_pose(&"tilted"):
		_fail("Could not prepare the tilted Castle pose.")
		return
	var control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	await process_frame
	if control.nearest_hotspot(370.0) != null:
		_fail("There is no out-of-range space between control walkway hotspots.")
		return
	control._inspect(control.return_console)
	control._advance_dialogue()
	if control.mode != &"roam" or state.flags.get("control_return_test_started", false):
		_fail("The console started before Kath made both observations.")
		return
	control._inspect(control.erin_station)
	control._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("control_erin_briefed", false):
		_fail("Esc committed Erin's unfinished briefing.")
		return
	control._inspect(control.erin_station)
	for i in 3:
		control._advance_dialogue()
	if not state.flags.get("control_erin_briefed", false) or not state.has_note(&"castle-basket-sketch"):
		_fail("Erin's completed briefing did not record the basket sketch.")
		return
	control._inspect(control.position_dial)
	for i in 2:
		control._advance_dialogue()
	if not state.flags.get("control_dial_checked", false) or not state.has_note(&"castle-position-baseline"):
		_fail("The dial observation did not persist.")
		return
	control._inspect(control.return_console)
	for i in 2:
		control._advance_dialogue()
	if control.mode != &"cutscene" or not state.flags.get("control_return_test_started", false):
		_fail("The completed setup did not start the on-site return test.")
		return
	control._unhandled_input(_key(KEY_ESCAPE))
	if control.mode != &"cutscene" or state.castle_pose != &"tilted" or control.kath.controls_enabled:
		_fail("The cutscene could be interrupted or committed the pose too early.")
		return
	var deadline := Time.get_ticks_msec() + 12000
	while state.castle_pose != &"inverted" and Time.get_ticks_msec() < deadline:
		await process_frame
	if state.castle_pose != &"inverted" or not state.flags.get("control_inversion_complete", false):
		_fail("The wing did not finish its continuous on-site inversion.")
		return
	if control.get_node("FixedArchitecture").rotation != 0.0 or control.get_node("SupportRing").rotation != 0.0:
		_fail("The fixed tower or support ring rotated with the wing.")
		return
	if not is_equal_approx(control.castle_wing_pivot.rotation, state.castle_pose_angle_radians() - control.SOURCE_WING_POSE_ANGLE):
		_fail("The finished wing pose disagrees with shared state.")
		return
	if control.erin.visible or control.nearest_hotspot(control.erin_station.approach_x) == control.erin_station:
		_fail("Erin remained on the fixed walkway after reaching the inner ledge.")
		return
	if not control.lower_service_hatch_art.visible or control.nearest_hotspot(control.lower_service_hatch.approach_x) != control.lower_service_hatch:
		_fail("The on-site inversion did not uncover the fixed tower's lower service hatch.")
		return
	if not state.has_note(&"castle-on-site-inversion") or control.mode != &"dialogue":
		_fail("The completed inversion did not provide its observation and aftermath dialogue.")
		return
	control._close_overlay()
	control.kath.position.x = 150.0
	control._unhandled_input(_key(KEY_E))
	await process_frame
	var road = current_scene
	if road == null or road.name != "ServiceRoad" or state.castle_pose != &"inverted":
		_fail("Returning to the road lost the inverted pose.")
		return
	if not is_equal_approx(road.castle_wing_pivot.rotation, state.castle_pose_angle_radians()):
		_fail("The road did not show the same inverted wing.")
		return
	road._inspect(road.get_node("SlackCable"))
	road._advance_dialogue()
	road._advance_dialogue()
	if not state.has_note(&"road-inverted-wing"):
		_fail("The road repeated its stale tilted-wing observation.")
		return
	var note_count: int = state.notes.size()
	road._inspect(road.get_node("SlackCable"))
	road._advance_dialogue()
	road._advance_dialogue()
	if state.notes.size() != note_count:
		_fail("Repeat inspection duplicated the inverted-wing observation.")
		return
	road.kath.position.x = 1580.0
	road.kath.position.y = road.kath.floor_height_at(1580.0)
	road._process(0.016)
	if road.mode != &"roam" or not road.ui.prompt.visible or road.ui.chapter_end.visible:
		_fail("The inverted road still reopened the Prologue Complete card.")
		return
	road._unhandled_input(_key(KEY_E))
	await process_frame
	var reentry = current_scene
	if reentry == null or reentry.name != "CastleControlWalkway":
		_fail("The inverted road did not return to the official control walkway.")
		return
	if reentry.mode != &"roam" or reentry.erin.visible \
		or not is_equal_approx(reentry.castle_wing_pivot.rotation, state.castle_pose_angle_radians() - reentry.SOURCE_WING_POSE_ANGLE):
		_fail("Re-entering the control walkway replayed the test or restored Erin to the deck.")
		return
	print("PHASE3_STEP1_SMOKE_OK: gated observations, cancel, inversion, fixed tower, road and re-entry")
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_STEP1_SMOKE_FAIL: " + message)
	quit(1)
