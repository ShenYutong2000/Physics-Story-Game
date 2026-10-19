extends SceneTree

const MACHINE: PackedScene = preload("res://scenes/machine_room.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.notes.clear()
	state.flags.clear()
	state.flags["dawn_reached"] = true
	var machine := MACHINE.instantiate()
	root.add_child(machine)
	current_scene = machine
	await process_frame
	machine.kath.position.x = 1540.0
	machine._inspect(machine.service_road_exit)
	if current_scene != machine or machine.mode != &"dialogue":
		_fail("The Service Road must remain locked until the incident is complete.")
		return
	machine._close_dialogue(false)
	state.flags["incident_complete"] = true
	machine._inspect(machine.service_road_exit)
	await process_frame
	var road = current_scene
	if road == null or road.name != "ServiceRoad" or road.kath.position.x != 150.0:
		_fail("The completed incident did not open the road at its left entrance.")
		return
	if not is_equal_approx(road.kath.position.y, road.kath.floor_height_at(150.0)):
		_fail("Kath did not spawn on the sloped road floor.")
		return
	if is_equal_approx(road.kath.floor_height_at(150.0), road.kath.floor_height_at(1500.0)):
		_fail("The Service Road floor did not change height along its slope.")
		return
	road._close_dialogue(false)
	road.kath.position.x = 482.0
	road._inspect(road.get_node("RoadSign"))
	road._advance_dialogue()
	road._advance_dialogue()
	if not state.has_note(&"service-road-sign"):
		_fail("Inspecting the road sign did not add its note.")
		return
	road.kath.position.x = 900.0
	road._inspect(road.get_node("SlackCable"))
	road._advance_dialogue()
	road._advance_dialogue()
	if not state.has_note(&"road-gravity-observation"):
		_fail("Inspecting the hanging cable did not add the observation.")
		return
	road.kath.position.x = 1322.0
	road._inspect(road.get_node("ServiceGate"))
	if not state.flags.get("service_gate_open", false) or road.gate.frame != 1 or road.kath.right_limit < 1570.0:
		_fail("Opening the service gate did not persist or clear the road boundary.")
		return
	road._close_dialogue(false)
	road.kath.position.x = 1580.0
	road._process(0.016)
	if road.mode != &"dialogue" or not state.flags.get("service_road_end_reached", false) or not state.has_note(&"service-road-arrival"):
		_fail("The first castle arrival did not record its one-time observation and dialogue.")
		return
	road._advance_dialogue()
	road._advance_dialogue()
	road._process(0.016)
	if road.mode != &"chapter_end" or not road.ui.chapter_end.visible:
		_fail("Reaching the road end did not display the chapter handoff card.")
		return
	road._unhandled_input(_key(KEY_ENTER))
	if road.mode != &"roam" or not is_equal_approx(road.kath.position.x, 1510.0):
		_fail("The chapter card did not return the player to the road on Enter.")
		return
	road.kath.position.x = 100.0
	road._inspect(road.get_node("MachineDoor"))
	await process_frame
	machine = current_scene
	if machine == null or machine.name != "MachineRoom" or not is_equal_approx(machine.kath.position.x, 1510.0):
		_fail("The road return did not place Kath beside the Machine Room exit.")
		return
	machine._inspect(machine.service_road_exit)
	await process_frame
	road = current_scene
	if road == null or road.name != "ServiceRoad" or not is_equal_approx(road.kath.position.x, 150.0):
		_fail("The Machine Room exit did not return Kath to the road entrance.")
		return
	if road.gate.frame != 1 or road.kath.right_limit < 1570.0:
		_fail("The opened gate state did not survive a second road visit.")
		return
	road.kath.position.x = 1580.0
	road._process(0.016)
	if road.mode != &"chapter_end" or not road.ui.chapter_end.visible or not state.has_note(&"service-road-arrival"):
		_fail("Returning to the road should reopen the card without repeating the first-arrival dialogue or note.")
		return
	if state.notes.size() != 3:
		_fail("Repeated travel or inspection duplicated Service Road notes.")
		return
	print("WEEK6_SMOKE_OK: gated exit, slope spawn, road observations, persistent gate, chapter card, two-way travel")
	road.queue_free()
	state.queue_free()
	for i in 4:
		await process_frame
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("WEEK6_SMOKE_FAIL: " + message)
	quit(1)
