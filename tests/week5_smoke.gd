extends SceneTree

const ROOM: PackedScene = preload("res://scenes/kath_room.tscn")
const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const UPPER: PackedScene = preload("res://scenes/upper_stacks.tscn")
const MACHINE: PackedScene = preload("res://scenes/machine_room.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.notes.clear()
	state.flags.clear()
	state.pending_spawn_tag = &"from-upper-stacks"
	for note_id in state.HALL_NOTE_IDS:
		state.add_note_once(note_id, String(note_id), "Checked")
	state.add_note_once(&"newton-note", "A torn page", "F = ma")
	state.flags["machine_baseline_recorded"] = true
	state.flags["stacks_page_collected"] = true
	state.flags["stacks_case_open"] = true
	state.flags["stacks_bucket_moved"] = true
	state.flags["stacks_intro_seen"] = true
	state.flags["machine_intro_seen"] = true

	var room := ROOM.instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	room._close_dialogue(false)
	room.kath.position.x = 1281.0
	room._interact()
	if not state.flags.get("room_lamp_on", false) or room.lamp.frame != 1:
		_fail("The desk lamp did not switch on.")
		return
	room._close_dialogue(false)
	room.kath.position.x = 1028.0
	room._interact()
	if room.mode != &"comparison":
		_fail("The notebook comparison did not open.")
		return
	room._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("room_notebook_compared", false):
		_fail("Escaping the comparison should cancel the notebook record.")
		return
	room._interact()
	room._unhandled_input(_key(KEY_ENTER))
	if not state.flags.get("room_notebook_compared", false) or not state.has_note(&"notebook-match"):
		_fail("Confirming the page did not record the notebook match.")
		return
	room._close_dialogue(false)
	room.kath.position.x = 560.0
	room._interact()
	if not state.flags.get("dawn_reached", false) or room.far.texture.resource_path.find("archive-dawn-city") < 0:
		_fail("Resting did not transition the world to dawn.")
		return
	room._close_dialogue(false)
	room.kath.position.x = 646.0
	room._interact()
	if not state.flags.get("room_bag_packed", false) or room.satchel.frame != 1:
		_fail("Packing the satchel did not persist.")
		return
	room._close_dialogue(false)
	room.kath.position.x = 100.0
	room._interact()
	await process_frame
	var upper := current_scene
	if upper == null or upper.name != "UpperStacks" or not state.flags.get("prologue_departure_ready", false):
		_fail("The prepared route did not return to the Upper Stacks.")
		return
	if upper.far.texture.resource_path.find("archive-dawn-city") < 0:
		_fail("The Upper Stacks window did not retain the dawn state.")
		return
	upper.kath.position.x = 500.0
	upper._handle_interact()
	await process_frame
	var hall := current_scene
	if hall == null or hall.name != "LibraryHall" or not state.flags.get("machine_incident_active", false):
		_fail("Returning to the Hall did not trigger the one-time machine alarm.")
		return
	if hall.far.texture.resource_path.find("archive-dawn-city") < 0:
		_fail("The Hall did not retain the dawn background.")
		return
	hall._close_dialogue(false)
	hall._unhandled_input(_key(KEY_ESCAPE))
	if hall.mode != &"paused":
		_fail("The Hall could not pause after the dawn alarm.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	hall._inspect(hall.archive_door)
	await process_frame
	var machine := current_scene
	if machine == null or machine.name != "MachineRoom":
		_fail("The Hall archive door did not enter the active Machine Room incident.")
		return
	machine._close_dialogue(false)
	machine.kath.position.x = 1136.0
	machine._inspect(machine.get_node("Gauge"))
	if machine.mode != &"console":
		_fail("The emergency control console did not open.")
		return
	machine._unhandled_input(_key(KEY_E))
	machine._unhandled_input(_key(KEY_E))
	if not state.flags.get("incident_valve_two_open", false) or not state.flags.get("incident_valve_four_open", false):
		_fail("The console did not operate levers 2 and 4 in sequence.")
		return
	machine._process(2.0)
	if not state.flags.get("incident_needle_rebounded", false):
		_fail("The gauge did not rebound after the brief drop.")
		return
	machine._unhandled_input(_key(KEY_ESCAPE))
	machine._inspect(machine.return_exit)
	for i in 3:
		await process_frame
	hall = current_scene
	if hall == null or hall.name != "LibraryHall":
		_fail("The player could not leave during the active incident.")
		return
	hall._inspect(hall.archive_door)
	for i in 3:
		await process_frame
	machine = current_scene
	if machine == null or machine.name != "MachineRoom" \
		or machine.lever_two.frame != 1 or machine.lever_four.frame != 1 \
		or not state.flags.get("incident_needle_rebounded", false):
		_fail("Re-entering the Machine Room did not restore the incident state.")
		return
	machine.kath.position.x = 1338.0
	machine._unhandled_input(_key(KEY_E))
	if not state.flags.get("incident_drive_stopped", false):
		_fail("The emergency stop did not stop the local drive.")
		return
	await create_timer(3.7).timeout
	if not state.flags.get("incident_tilt_observed", false) or not state.flags.get("incident_complete", false) or not state.has_note(&"castle-alarm"):
		_fail("The remote castle tilt did not finish and record its observed result.")
		return
	if state.castle_pose != &"tilted" or not is_equal_approx(state.castle_pose_angle_radians(), deg_to_rad(12.0)):
		_fail("The incident did not leave the shared castle pose at a 12-degree tilt.")
		return
	var incident_note := state.notes.back() as Dictionary
	if incident_note.get("title", "") != "Remote tilt observed" \
		or incident_note.get("body", "").find("do not know whether the two events are connected") < 0:
		_fail("The incident note did not preserve the observation and uncertainty about the cause.")
		return
	if machine.mode != &"dialogue":
		_fail("The post-incident decision dialogue did not appear.")
		return
	machine._close_dialogue(false)
	machine._inspect(machine.return_exit)
	for i in 3:
		await process_frame
	hall = current_scene
	if hall == null or hall.name != "LibraryHall" or not state.flags.get("incident_return_line_seen", false):
		_fail("The completed incident did not return to the Hall with its one-time follow-up.")
		return
	if hall.dialogue_lines.is_empty() or not hall.dialogue_lines[0].contains("still tilted"):
		_fail("The Hall return dialogue did not describe the wing's tilted pose.")
		return
	hall._close_dialogue(false)
	hall._inspect(hall.archive_door)
	for i in 3:
		await process_frame
	machine = current_scene
	if machine == null or machine.name != "MachineRoom":
		_fail("The completed incident did not allow travel back into the Machine Room.")
		return
	machine.kath.position.x = 1540.0
	machine._inspect(machine.service_road_exit)
	for i in 3:
		await process_frame
	var road = current_scene
	if road == null or road.name != "ServiceRoad" \
		or not is_equal_approx(road.castle_wing_pivot.rotation, state.castle_pose_angle_radians()):
		_fail("The completed incident did not open a road with the shared tilted castle pose.")
		return
	road._close_dialogue(false)
	road.kath.position.x = 1322.0
	road._inspect(road.get_node("ServiceGate"))
	road._close_dialogue(false)
	road.kath.position.x = 1580.0
	road._process(0.016)
	if road.mode != &"dialogue":
		_fail("The first Castle arrival did not start its observation dialogue.")
		return
	road._advance_dialogue()
	road._advance_dialogue()
	road._process(0.016)
	if road.mode != &"chapter_end":
		_fail("The chapter card did not follow the first Castle arrival dialogue.")
		return
	road._unhandled_input(_key(KEY_ENTER))
	for i in 3:
		await process_frame
	var control = current_scene
	if control == null or control.name != "CastleControlWalkway" or state.castle_pose != &"tilted":
		_fail("The real incident route did not enter the Control Walkway in the tilted stage.")
		return
	control._close_overlay()
	control.kath.position.x = 150.0
	control._unhandled_input(_key(KEY_E))
	for i in 3:
		await process_frame
	road = current_scene
	if road == null or road.name != "ServiceRoad" or road.mode != &"roam":
		_fail("The real incident route could not return from the Control Walkway.")
		return
	road.queue_free()
	await process_frame
	for flag_name in ["incident_valve_two_open", "incident_valve_four_open", "incident_valves_complete", "incident_drive_stopped", "incident_needle_rebounded", "incident_tilt_started", "incident_tilt_observed", "incident_complete"]:
		state.flags[flag_name] = false
	state.pending_spawn_tag = &""
	var early_stop_machine := MACHINE.instantiate()
	root.add_child(early_stop_machine)
	current_scene = early_stop_machine
	await process_frame
	early_stop_machine.kath.position.x = 1338.0
	early_stop_machine._inspect(early_stop_machine.stop_hotspot)
	if not state.flags.get("incident_drive_stopped", false):
		_fail("The early-stop recovery path did not stop the drive first.")
		return
	early_stop_machine._close_dialogue(false)
	early_stop_machine.kath.position.x = 1136.0
	early_stop_machine._inspect(early_stop_machine.get_node("Gauge"))
	early_stop_machine._unhandled_input(_key(KEY_E))
	early_stop_machine._unhandled_input(_key(KEY_E))
	await create_timer(3.7).timeout
	if not state.flags.get("incident_complete", false):
		_fail("Operating both valves after an early stop did not complete recovery.")
		return
	print("WEEK5_SMOKE_OK: comparison cancel/confirm, dawn, packing, alarm, pause, lever rebound, incident re-entry, both stop orders, remote castle tilt")
	early_stop_machine.queue_free()
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
	push_error("WEEK5_SMOKE_FAIL: " + message)
	quit(1)
