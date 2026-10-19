extends SceneTree
## Verify pose-driven layers without unlocking any Chapter I gameplay route.

const CONTROL: PackedScene = preload("res://scenes/castle_control_walkway.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags["control_walkway_intro_seen"] = true
	if not state.transition_castle_pose(&"tilted"):
		_fail("Could not enter the tilted pose.")
		return
	var control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	await process_frame
	if control.get_node_or_null("Backdrop") != null:
		_fail("The temporary flattened backdrop is still in the scene.")
		return
	if not is_zero_approx(control.castle_wing_pivot.rotation):
		_fail("The painted 12-degree tilt did not align to the shared tilted pose.")
		return
	if control.get_node("FixedArchitecture").rotation != 0.0:
		_fail("The fixed tower and support ring rotated with the wing.")
		return
	if control.get_node("SupportRing").rotation != 0.0 or control.get_node("ControlDial").rotation != 0.0:
		_fail("A fixed mechanism rotated with the wing.")
		return
	if control.get_node("ShortGuardrail").z_index <= control.kath.z_index:
		_fail("The near guardrail cannot occlude Kath.")
		return
	if control.get_node("FrontParapet").z_index <= control.kath.z_index:
		_fail("The near parapet cannot occlude the player.")
		return
	if state.notes.size() != 0 or state.castle_pose != &"tilted":
		_fail("Entering the art scene advanced the story.")
		return
	control.queue_free()
	await process_frame
	if not state.transition_castle_pose(&"inverted"):
		_fail("Could not inspect the inverted preview pose.")
		return
	control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	await process_frame
	var expected_angle: float = state.castle_pose_angle_radians() - deg_to_rad(12.0)
	if not is_equal_approx(control.castle_wing_pivot.rotation, expected_angle):
		_fail("The wing did not follow the shared inverted pose.")
		return
	if not is_equal_approx(control.dial_needle_pivot.rotation, deg_to_rad(40.0)):
		_fail("The bounded status pointer did not indicate the inverted pose.")
		return
	if control.get_node("FixedArchitecture").rotation != 0.0:
		_fail("The fixed control tower rotated in the inverted preview.")
		return
	if control.get_node("SupportRing").rotation != 0.0 or control.get_node("ControlDial").rotation != 0.0:
		_fail("The detached fixed mechanisms rotated in the inverted preview.")
		return
	print("PHASE2_STEP3_SMOKE_OK: separated art, foreground depth, fixed ring and shared wing/needle pose")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
