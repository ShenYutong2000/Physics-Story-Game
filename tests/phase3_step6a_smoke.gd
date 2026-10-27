extends SceneTree
## First passenger-rescue checkpoint: raise and dock the empty basket, without boarding.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	state.flags["shaft_rig_inspected"] = true
	state.flags["shaft_tools_loaded"] = true
	state.flags["shaft_rail_removed"] = true
	state.flags["shaft_tool_trip_complete"] = true
	state.flags["shaft_passenger_rethread_complete"] = true
	state.flags["shaft_empty_test_complete"] = true
	state.flags["shaft_lower_dock_locked"] = true
	state.flags["shaft_basket_progress"] = 0.0
	var shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	shaft._inspect(shaft.winch_console)
	if shaft.mode != &"dialogue":
		_fail("The lower clamp did not block the winch.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ENTER))
	if state.flags.get("shaft_upper_dock_locked", false):
		_fail("Erin docked a basket that was not at her ledge.")
		return
	shaft._inspect(shaft.lower_dock_latch)
	shaft._unhandled_input(_key(KEY_ENTER))
	if state.flags.get("shaft_lower_dock_locked", true):
		_fail("The lower dock did not release after the empty test.")
		return
	shaft._inspect(shaft.winch_console)
	if shaft.mode != &"winch" or shaft._winch_phase() != &"passenger_raise":
		_fail("The full empty-basket lift did not unlock.")
		return
	Input.action_press("move_up")
	shaft._process_winch(3.0)
	Input.action_release("move_up")
	var first_height: float = shaft.basket_progress
	if first_height <= shaft.EMPTY_TEST_LIMIT or first_height >= 0.995:
		_fail("The empty basket did not rise beyond the former short-test limit.")
		return
	shaft._process_winch(0.1)
	if not is_equal_approx(shaft.basket_progress, first_height):
		_fail("Releasing Up failed to hold the basket.")
		return
	Input.action_press("move_down")
	shaft._process_winch(1.0)
	Input.action_release("move_down")
	if shaft.basket_progress >= first_height:
		_fail("The basket could not reverse before reaching Erin.")
		return
	var saved_height: float = shaft.basket_progress
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.return_aperture)
	await process_frame
	if current_scene == shaft:
		_fail("The return passage failed during the empty lift.")
		return
	state.travel_to("res://scenes/chapter1_maintenance_shaft.tscn", &"from-inverted-room")
	await process_frame
	shaft = current_scene
	if shaft == null or absf(shaft.basket_progress - saved_height) > 0.001 or state.flags.get("shaft_upper_dock_locked", false):
		_fail("The partial lift or docking state changed across a round trip.")
		return
	shaft._inspect(shaft.winch_console)
	Input.action_press("move_up")
	shaft._process_winch(10.0)
	Input.action_release("move_up")
	shaft._process_winch(0.1)
	if shaft.basket_progress < 0.995 or state.flags.get("shaft_upper_dock_locked", false):
		_fail("The empty basket failed to reach the upper ledge or docked automatically.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("shaft_upper_dock_locked", false):
		_fail("Esc committed the upper docking conversation.")
		return
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_upper_dock_locked", false) or state.flags.get("shaft_rescue_phase", &"") != &"upper_docked":
		_fail("Erin did not fasten the upper catch.")
		return
	if not shaft.upper_dock_clamp.visible or shaft.basket_body.texture != shaft.BASKET_OPEN or not shaft.erin.visible or shaft.get_node("BasketRig/ErinInBasket").visible:
		_fail("The dock, open gate or Erin's unboarded position is wrong.")
		return
	shaft._inspect(shaft.winch_console)
	if shaft.mode != &"dialogue":
		_fail("The docked basket could still be operated.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.return_aperture)
	await process_frame
	state.travel_to("res://scenes/chapter1_maintenance_shaft.tscn", &"from-inverted-room")
	await process_frame
	shaft = current_scene
	if shaft == null or not shaft.upper_dock_clamp.visible or shaft.basket_progress < 0.995 or state.notes.size() != 0:
		_fail("The upper dock or notes changed after returning.")
		return
	print("PHASE3_STEP6A_SMOKE_OK: full empty lift, stop, upper dock, open gate and persistence")
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_STEP6A_SMOKE_FAIL: " + message)
	quit(1)
