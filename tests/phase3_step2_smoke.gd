extends SceneTree
## Official lower hatch, inverted-room observations, cancellation and return.

const CONTROL: PackedScene = preload("res://scenes/castle_control_walkway.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"upright"
	state.flags["incident_complete"] = true
	state.flags["control_walkway_intro_seen"] = true
	var control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	await process_frame
	if control.lower_service_hatch_art.visible or control.nearest_hotspot(615.0) == control.lower_service_hatch:
		_fail("Lower hatch appeared before the on-site inversion.")
		return
	state.transition_castle_pose(&"tilted")
	state.transition_castle_pose(&"inverted")
	state.flags["control_inversion_complete"] = true
	control.lower_service_hatch_art.visible = true
	control.kath.position.x = 615.0
	control._unhandled_input(_key(KEY_E))
	await process_frame
	var room = current_scene
	if room == null or room.name != "Chapter1InvertedRoom":
		_fail("The fixed-tower lower hatch did not enter the official inverted room.")
		return
	if room.mode != &"dialogue" or not is_equal_approx(room.kath.position.y, 806.0):
		_fail("Room entry dialogue or floor spawn is wrong.")
		return
	room._unhandled_input(_key(KEY_ESCAPE))
	if room.mode != &"roam" or room.nearest_hotspot(490.0) != null:
		_fail("There is no free walking space between the entrance and observations.")
		return
	room._inspect(room.shaft_ladder)
	room._advance_dialogue()
	if state.flags.get("room_ladder_checked", false):
		_fail("The ladder was marked before Kath checked the real down direction.")
		return
	room._inspect(room.water_path)
	room._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("room_water_observed", false) or state.has_note(&"castle-water-path"):
		_fail("Esc committed an unfinished water observation.")
		return
	room._inspect(room.plumb_weight)
	room._advance_dialogue()
	room._advance_dialogue()
	if not state.flags.get("room_plumb_observed", false) or state.flags.get("castle_down_confirmed", false):
		_fail("The chain observation did not persist independently.")
		return
	room._inspect(room.water_path)
	room._advance_dialogue()
	room._advance_dialogue()
	if room.mode != &"dialogue" or not state.flags.get("room_water_observed", false):
		_fail("Completing both observations did not offer the comparison.")
		return
	room._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("castle_down_confirmed", false):
		_fail("Esc committed the unfinished down-direction comparison.")
		return
	room._inspect(room.water_path)
	room._advance_dialogue()
	room._advance_dialogue()
	if not state.flags.get("castle_down_confirmed", false) or not state.has_note(&"castle-down-confirmed"):
		_fail("The completed comparison was not recorded.")
		return
	room._inspect(room.shaft_ladder)
	room._advance_dialogue()
	room._advance_dialogue()
	if not state.flags.get("room_ladder_checked", false) or not state.has_note(&"castle-shaft-access"):
		_fail("The maintenance ladder did not mark the next route.")
		return
	var note_count: int = state.notes.size()
	room._inspect(room.plumb_weight)
	room._advance_dialogue()
	room._advance_dialogue()
	if state.notes.size() != note_count:
		_fail("Repeated observation created duplicate notes.")
		return
	room.kath.position.x = 145.0
	room._unhandled_input(_key(KEY_E))
	await process_frame
	var reentry = current_scene
	if reentry == null or reentry.name != "CastleControlWalkway" or not reentry.lower_service_hatch_art.visible:
		_fail("Returning to the fixed tower lost the lower hatch.")
		return
	if reentry.mode != &"roam" or reentry.erin.visible or reentry.kath.position.x > 600.0:
		_fail("Return spawn or persistent aftermath is wrong.")
		return
	print("PHASE3_STEP2_SMOKE_OK: gated hatch, room observations, cancel, comparison, ladder and return")
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_STEP2_SMOKE_FAIL: " + message)
	quit(1)
