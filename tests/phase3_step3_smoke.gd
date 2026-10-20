extends SceneTree
## Official room ladder and shaft round-trip; preview controls remain isolated.

const ROOM: PackedScene = preload("res://scenes/chapter1_inverted_room.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	state.flags["control_inversion_complete"] = true
	state.flags["inverted_room_intro_seen"] = true
	var room = ROOM.instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	room._inspect(room.shaft_ladder)
	room._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("room_ladder_checked", false) or room.kath.locomotion_mode != &"walk":
		_fail("An unconfirmed ladder inspection opened the route.")
		return
	state.flags["castle_down_confirmed"] = true
	room._inspect(room.shaft_ladder)
	room._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("room_ladder_checked", false):
		_fail("Esc committed the ladder inspection.")
		return
	room._inspect(room.shaft_ladder)
	room._advance_dialogue()
	room._advance_dialogue()
	if not state.flags.get("room_ladder_checked", false):
		_fail("Completing the ladder inspection did not open climbing.")
		return
	var note_count: int = state.notes.size()
	room.kath.position.x = 1460.0
	room._unhandled_input(_key(KEY_E))
	if room.kath.locomotion_mode != &"climb" or not is_equal_approx(room.kath.position.y, 776.0):
		_fail("E at the ladder foot did not start climbing.")
		return
	Input.action_press("move_up")
	room.kath._physics_process(0.1)
	Input.action_release("move_up")
	if room.kath.position.y >= 776.0 or room.nearest_hotspot(room.kath.position.x) != null:
		_fail("Climbing failed or ground hotspots remained active.")
		return
	var paused_y: float = room.kath.position.y
	room._unhandled_input(_key(KEY_ESCAPE))
	room.kath._physics_process(0.1)
	if room.mode != &"paused" or not is_equal_approx(room.kath.position.y, paused_y):
		_fail("Pause moved Kath on the ladder.")
		return
	room._unhandled_input(_key(KEY_ESCAPE))
	room._unhandled_input(_key(KEY_J))
	if room.mode != &"journal" or not is_equal_approx(room.kath.position.y, paused_y):
		_fail("The journal lost the climbing position.")
		return
	room._unhandled_input(_key(KEY_J))
	room.kath.position.y = 475.0
	room._unhandled_input(_key(KEY_E))
	await process_frame
	var shaft = current_scene
	if shaft == null or shaft.name != "Chapter1MaintenanceShaft":
		_fail("The ladder top did not enter the official shaft.")
		return
	if not is_equal_approx(shaft.kath.position.y, 790.0) or shaft.kath.position.x < 90.0:
		_fail("Shaft spawn is outside the safe floor.")
		return
	if shaft.get_node("BasketRig/ToolCrate").visible or shaft.get_node("MovingPulley").visible:
		_fail("Preview rescue state leaked into the official shaft.")
		return
	if shaft.mode != &"dialogue" or not state.flags.get("shaft_intro_seen", false):
		_fail("The first shaft entry did not explain the fixed-platform connection.")
		return
	shaft._unhandled_input(_key(KEY_ENTER))
	shaft._unhandled_input(_key(KEY_E))
	if current_scene != shaft or shaft.get_node("BasketRig/ToolCrate").visible:
		_fail("E away from the exit triggered a preview action or a scene change.")
		return
	shaft.kath.position.x = 190.0
	shaft._unhandled_input(_key(KEY_E))
	await process_frame
	room = current_scene
	if room == null or room.name != "Chapter1InvertedRoom" or room.kath.locomotion_mode != &"climb":
		_fail("The return aperture did not restore the ladder-top spawn.")
		return
	if not is_equal_approx(room.kath.position.y, 475.0) or state.notes.size() != note_count:
		_fail("Round-trip position or note persistence is wrong.")
		return
	Input.action_press("move_down")
	room.kath._physics_process(3.0)
	Input.action_release("move_down")
	room._process(0.016)
	if room.kath.locomotion_mode != &"walk" or not is_equal_approx(room.kath.position.x, 1460.0) or not is_equal_approx(room.kath.position.y, 806.0):
		_fail("Descending did not restore safe walking at the ladder foot.")
		return
	room._unhandled_input(_key(KEY_E))
	room.kath.position.y = 475.0
	room._unhandled_input(_key(KEY_E))
	await process_frame
	shaft = current_scene
	if shaft == null or shaft.name != "Chapter1MaintenanceShaft" or shaft.mode != &"roam" or state.notes.size() != note_count:
		_fail("Re-entering the shaft replayed the intro or duplicated a note.")
		return
	print("PHASE3_STEP3_SMOKE_OK: gated climb, pause, shaft visit and ladder-top return")
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_STEP3_SMOKE_FAIL: " + message)
	quit(1)
