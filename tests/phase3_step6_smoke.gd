extends SceneTree
## Occupied load check, controlled descent, safe dock and Erin's return.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	for flag in ["shaft_rig_inspected", "shaft_tools_loaded", "shaft_rail_removed", "shaft_tool_trip_complete", "shaft_passenger_rethread_complete", "shaft_empty_test_complete", "shaft_upper_dock_locked"]:
		state.flags[flag] = true
	state.flags["shaft_rescue_phase"] = &"upper_docked"
	state.flags["shaft_basket_progress"] = 1.0
	var shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("shaft_erin_aboard", false):
		_fail("Esc boarded Erin.")
		return
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ENTER))
	await create_timer(1.9).timeout
	if not state.flags.get("shaft_erin_aboard", false) or shaft.erin.visible or not shaft.erin_in_basket.visible or absf(shaft.load_indicator.rotation + 0.38) > 0.02:
		_fail("Erin did not board the secured basket or the unloaded needle stayed fixed.")
		return
	_dismiss(shaft)
	shaft._inspect(shaft.return_aperture)
	if current_scene != shaft or shaft.mode != &"dialogue":
		_fail("Kath left while Erin was in the basket.")
		return
	_dismiss(shaft)
	shaft._inspect(shaft.winch_console)
	if shaft.mode != &"winch" or shaft._rescue_phase() != &"load_tension":
		_fail("The secured load did not open the tension check.")
		return
	Input.action_press("move_up")
	shaft._process_load_tension(3.0)
	Input.action_release("move_up")
	shaft._process_load_tension(0.1)
	if not state.flags.get("shaft_load_tensioned", false) or not state.flags.get("shaft_brake_hold_observed", false) or shaft.basket_progress < 0.995 or shaft.load_indicator.rotation > -0.09:
		_fail("Taking up slack failed to shift the needle or show the brake holding.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	shaft._inspect(shaft.winch_console)
	if shaft.mode != &"load_check":
		_fail("The loaded inspection did not open.")
		return
	shaft._unhandled_input(_key(KEY_E))
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.has_note(&"shaft-occupied-load") or state.flags.get("shaft_load_verified", false):
		_fail("Esc committed unfinished load checks.")
		return
	shaft._inspect(shaft.winch_console)
	for selected in [2, 0, 3]:
		_select_and_check(shaft, selected)
	shaft._unhandled_input(_key(KEY_ENTER))
	if state.flags.get("shaft_load_verified", false):
		_fail("Three checks incorrectly released the passenger catch.")
		return
	_select_and_check(shaft, 1)
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_load_verified", false) or not state.has_note(&"shaft-occupied-load") or not state.flags.get("shaft_upper_dock_locked", false):
		_fail("The four checks did not record the load while retaining the catch.")
		return
	_dismiss(shaft)
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ENTER))
	if state.flags.get("shaft_upper_dock_locked", true) or shaft._rescue_phase() != &"passenger_descent" or shaft.basket_body.texture != shaft.BASKET_CLOSED:
		_fail("The verified basket did not release for descent.")
		return
	shaft._inspect(shaft.winch_console)
	Input.action_press("move_down")
	shaft._process_passenger_descent(1.0)
	Input.action_release("move_down")
	var first_speed: float = shaft.descent_speed
	var first_height: float = shaft.basket_progress
	shaft._process_passenger_descent(0.1)
	if first_speed <= 0.0 or shaft.descent_speed >= first_speed or shaft.basket_progress >= first_height:
		_fail("Loaded descent failed to accelerate or passively slow when released.")
		return
	Input.action_press("shaft_brake")
	shaft._process_passenger_descent(0.5)
	Input.action_release("shaft_brake")
	if shaft.descent_speed > 0.001:
		_fail("Space did not brake the basket.")
		return
	shaft._unhandled_input(_key(KEY_ESCAPE))
	var held_height: float = shaft.basket_progress
	shaft._inspect(shaft.winch_console)
	shaft._process_passenger_descent(0.5)
	if absf(shaft.basket_progress - held_height) > 0.001:
		_fail("Closing the winch failed to hold height.")
		return
	Input.action_press("move_down")
	shaft._process_passenger_descent(6.0)
	Input.action_release("move_down")
	if not state.flags.get("shaft_safety_stopped", false) or shaft.basket_progress < 0.075 or shaft.basket_progress > 0.085:
		_fail("The safety catch did not stop an over-fast approach.")
		return
	Input.action_press("shaft_brake")
	shaft._process_passenger_descent(0.1)
	Input.action_release("shaft_brake")
	if state.flags.get("shaft_safety_stopped", false):
		_fail("Space did not reset the safety catch.")
		return
	var pulses := 0
	while shaft.mode == &"winch" and pulses < 40:
		Input.action_press("move_down")
		shaft._process_passenger_descent(0.25)
		Input.action_release("move_down")
		Input.action_press("shaft_brake")
		shaft._process_passenger_descent(0.12)
		Input.action_release("shaft_brake")
		pulses += 1
	if not state.flags.get("shaft_lower_arrived", false) or shaft.basket_progress > 0.005 or shaft.get_node("BasketRig/ErinInBasket").visible == false:
		_fail("Careful braking did not reach the lower berth with Erin aboard.")
		return
	_dismiss(shaft)
	shaft._inspect(shaft.lower_dock_latch)
	shaft._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("shaft_lower_dock_locked", false):
		_fail("Esc fastened the occupied lower dock.")
		return
	shaft._inspect(shaft.lower_dock_latch)
	shaft._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("shaft_lower_dock_locked", false) or shaft.loading_spur.scale.x < 0.15:
		_fail("The lower dock or loading spur did not secure the basket.")
		return
	shaft._inspect(shaft.lower_dock_latch)
	shaft._unhandled_input(_key(KEY_ENTER))
	await create_timer(3.65).timeout
	if not state.flags.get("shaft_rescue_complete", false) or not shaft.erin_at_lower.visible or shaft.erin_in_basket.visible or not state.has_note(&"shaft-rescue"):
		_fail("Erin did not cross onto the fixed lower platform.")
		return
	_dismiss(shaft)
	var note_count: int = state.notes.size()
	shaft._inspect(shaft.return_aperture)
	await process_frame
	if current_scene == shaft:
		_fail("The return path stayed locked after the rescue.")
		return
	state.travel_to("res://scenes/chapter1_maintenance_shaft.tscn", &"from-inverted-room")
	await process_frame
	shaft = current_scene
	if shaft == null or not shaft.erin_at_lower.visible or shaft.erin_in_basket.visible or state.notes.size() != note_count:
		_fail("Rescue visuals or notes changed after returning.")
		return
	print("PHASE3_STEP6_SMOKE_OK: boarding, load checks, braking, safety stop, docking and return")
	quit(0)


func _select_and_check(shaft: Node, index: int) -> void:
	while shaft.load_check_selection != index:
		shaft._unhandled_input(_key(KEY_D))
	shaft._unhandled_input(_key(KEY_E))


func _dismiss(shaft: Node) -> void:
	for i in 6:
		if shaft.mode != &"dialogue":
			return
		shaft._unhandled_input(_key(KEY_ENTER))


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_STEP6_SMOKE_FAIL: " + message)
	quit(1)
