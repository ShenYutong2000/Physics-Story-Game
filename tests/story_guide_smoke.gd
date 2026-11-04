extends SceneTree

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const StoryGuide = preload("res://scripts/story_guide.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.notes.clear()
	state.flags.clear()
	state.castle_pose = &"upright"
	state.pending_spawn_tag = &""
	var hall := HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	hall._close_dialogue(false)
	if not _expect(state, "hall"):
		return
	hall.ui._process(0.0)
	state.guide_idle_seconds = 76.0
	hall.ui._process(0.0)
	if not hall.ui.objective_reminder_shown or not hall.ui.guide_bubble.visible or hall.ui.guide_text.text.find("Press H") == -1 or hall.wick.reaction_time <= 0.0:
		_fail("An idle player did not receive Wick's optional hint reminder.")
		return
	hall.kath.position.x = 800.0
	hall._process(0.0)
	hall.ui._process(0.0)
	if hall.ui.prompt.visible or not hall.ui.discovery_markers[0].visible or hall.ui.discovery_markers[1].visible:
		_fail("A nearby clock did not show one discovery mark before E was in reach.")
		return
	hall.kath.position.x = 967.0
	hall._process(0.0)
	hall.ui._process(0.0)
	if not hall.ui.prompt.visible or not hall.ui.discovery_markers[0].visible:
		_fail("The E prompt and discovery mark did not agree at the clock.")
		return
	root.get_node("GameSettings").hints_enabled = false
	hall.ui._process(0.0)
	if hall.ui.guide_bubble.visible or not hall.ui.discovery_markers[0].visible:
		_fail("Turning optional hints off also hid the basic discovery mark.")
		return
	root.get_node("GameSettings").hints_enabled = true
	hall._unhandled_input(_key(KEY_J))
	hall.ui._process(0.0)
	if hall.ui.discovery_markers[0].visible:
		_fail("Discovery marks remained visible over the journal.")
		return
	if hall.ui.journal_progress.text.find("CURRENT OBJECTIVE\nComplete the evening rounds") == -1:
		_fail("The journal has no current objective.")
		return
	hall.ui._unhandled_input(_key(KEY_H))
	if hall.ui.hint_level != 0:
		_fail("H revealed a hint over the journal.")
		return
	hall._unhandled_input(_key(KEY_J))
	for level in range(1, 5):
		await _tap_key(KEY_H)
		if hall.ui.hint_level != mini(level, 3) or hall.ui.guide_text.text.find("HINT %d/3" % mini(level, 3)) == -1:
			_fail("H did not advance or cap the three hint levels.")
			return
	if hall.wick.reaction_time <= 0.0:
		_fail("Wick did not point toward the current hall objective.")
		return

	state.add_note_once(&"clock-housing", "Old clock", "Observation")
	hall.ui._process(0.0)
	var remaining_target: Dictionary = StoryGuide.focus_target(state, StoryGuide.current(state), hall.scene_file_path, hall.kath.position.x)
	if hall.ui.hint_level != 0 or hall.ui.objective_reminder_shown or remaining_target["id"] != &"maintenance-sheet":
		_fail("Progress inside the same objective did not reset hints and select an unfinished object.")
		return
	for note_id in [&"archive-door", &"maintenance-sheet"]:
		state.add_note_once(note_id, String(note_id), "Observation")
	hall.ui._process(0.0)
	if not _expect(state, "baseline") or hall.ui.hint_level != 0 or hall.ui.guide_bubble.visible:
		_fail("A new objective did not reset the hint level.")
		return
	var hall_exit: Dictionary = StoryGuide.focus_target(state, StoryGuide.current(state), hall.scene_file_path, hall.kath.position.x)
	if hall_exit["id"] != &"exit" or absf(hall_exit["position"].x - 120.0) > 1.0:
		_fail("Wick did not route the machine-room objective toward the hall exit.")
		return
	hall._unhandled_input(_key(KEY_J))
	if hall.ui.journal_progress.text.find("NEXT RELEVANT AREA  Machine Room") == -1 \
		or hall.ui.journal_progress.text.find("• archive-door") == -1:
		_fail("The journal did not show the next area and discovered clue.")
		return
	hall._unhandled_input(_key(KEY_J))
	hall.ui._unhandled_input(_key(KEY_H))
	if hall.ui.hint_level != 1:
		_fail("The next objective did not restart at hint one.")
		return
	var rebuilt_ui: CanvasLayer = load("res://scenes/hall_ui.tscn").instantiate()
	hall.add_child(rebuilt_ui)
	await process_frame
	rebuilt_ui._sync_objective()
	if rebuilt_ui.hint_level != 1:
		_fail("A new room UI lost the current objective's hint level.")
		return
	rebuilt_ui.queue_free()
	await process_frame

	state.flags["machine_baseline_recorded"] = true
	if not _expect(state, "leak"):
		return
	state.flags["stacks_bucket_moved"] = true
	if not _expect(state, "page"):
		return
	state.flags["stacks_page_collected"] = true
	state.flags["room_lamp_on"] = true
	state.flags["room_notebook_compared"] = true
	state.flags["room_rested"] = true
	state.flags["room_bag_packed"] = true
	if not _expect(state, "return_hall"):
		return
	state.flags["machine_incident_active"] = true
	state.flags["incident_valve_two_open"] = true
	state.flags["incident_valve_four_open"] = true
	state.flags["incident_drive_stopped"] = true
	state.flags["incident_tilt_observed"] = true
	state.flags["service_gate_open"] = true
	state.flags["service_road_end_reached"] = true
	state.flags["control_dial_checked"] = true
	state.flags["control_erin_briefed"] = true
	if not _expect(state, "return_test"):
		return
	state.flags["control_inversion_complete"] = true
	state.flags["room_water_observed"] = true
	var plumb_target: Dictionary = StoryGuide.focus_target(state, StoryGuide.current(state), "res://scenes/chapter1_inverted_room.tscn", 900.0)
	if plumb_target["id"] != &"room-plumb-weight":
		_fail("Wick pointed back to observed water instead of the unexamined weight.")
		return
	state.flags["room_water_observed"] = true
	state.flags["room_plumb_observed"] = true
	state.flags["castle_down_confirmed"] = true
	state.flags["room_ladder_checked"] = true
	state.flags["shaft_erin_contacted"] = true
	state.flags["shaft_rig_inspected"] = true
	state.flags["shaft_tools_loaded"] = true
	state.flags["shaft_tool_trip_complete"] = true
	state.flags["shaft_passenger_rig_inspected"] = true
	state.flags["shaft_top_anchor_inspected"] = true
	if not _expect(state, "lock_empty"):
		return
	state.flags["shaft_lower_dock_locked"] = true
	if not _expect(state, "take_rope"):
		return
	state.flags["shaft_long_rope_taken"] = true
	if not _expect(state, "rethread"):
		return
	state.flags["shaft_passenger_rethread_complete"] = true
	if not _expect(state, "empty_test"):
		return
	state.flags["shaft_empty_test_complete"] = true
	if not _expect(state, "raise_empty"):
		return
	state.flags["shaft_basket_progress"] = 1.0
	var tube_target: Dictionary = StoryGuide.focus_target(state, StoryGuide.current(state), "res://scenes/chapter1_maintenance_shaft.tscn", 450.0)
	if tube_target["id"] != &"shaft-speaking-tube":
		_fail("The raised basket did not redirect Wick from the winch to the speaking tube.")
		return
	state.flags["shaft_upper_dock_locked"] = true
	if not _expect(state, "board_erin"):
		return
	state.flags["shaft_erin_aboard"] = true
	if not _expect(state, "tension"):
		return
	state.flags["shaft_load_tensioned"] = true
	if not _expect(state, "check_load"):
		return
	state.flags["shaft_load_verified"] = true
	if not _expect(state, "lower_erin"):
		return
	state.flags["shaft_lower_arrived"] = true
	state.flags["shaft_lower_dock_locked"] = false
	if not _expect(state, "lower_dock"):
		return
	state.flags["shaft_lower_dock_locked"] = true
	state.flags["shaft_rescue_complete"] = true
	state.flags["engine_chart_seen"] = true
	var engine_target: Dictionary = StoryGuide.focus_target(state, StoryGuide.current(state), "res://scenes/chapter1_engine_room.tscn", 335.0)
	if engine_target["id"] == &"engine-wall-chart":
		_fail("Wick pointed to an engine observation already recorded.")
		return
	state.flags.erase("engine_chart_seen")
	state.flags["engine_fault_traced"] = true
	state.flags["engine_drive_isolated"] = true
	state.flags["engine_jam_cleared"] = true
	state.flags["engine_checks_verified"] = true
	state.castle_pose = &"restored"
	if not _expect(state, "archive"):
		return
	state.flags["observatory_archive_complete"] = true
	state.flags["observatory_page_stitched"] = true
	if not _expect(state, "talk_erin"):
		return
	state.flags["chapter1_complete"] = true
	if not _expect(state, "complete"):
		return

	# A checkpoint restores evidence first; the UI must derive the same objective.
	var test_save := "res://.godot/story-guide-checkpoint-test.json"
	state.save_path_override = test_save
	state.persistence_enabled = true
	state.flags.clear()
	state.castle_pose = &"upright"
	state.flags["machine_baseline_recorded"] = true
	state.flags["stacks_bucket_moved"] = true
	state.add_note_once(&"leak-observation", "A leak contained", "The bucket caught the water.")
	if not state.save_checkpoint("res://scenes/upper_stacks.tscn"):
		_fail("Could not write a temporary checkpoint for the objective reload check.")
		return
	state.flags.clear()
	state.notes.clear()
	state.persistence_enabled = false
	if not state.resume_checkpoint():
		_fail("Could not reload the temporary checkpoint.")
		return
	await process_frame
	var upper := current_scene
	if upper == null or upper.scene_file_path != "res://scenes/upper_stacks.tscn" or upper.ui._sync_objective()["id"] != "page":
		_fail("The reloaded scene did not recover its current objective.")
		return
	upper.ui.show_journal(state.notes, state.hall_checks_complete(), true, true, false)
	if upper.ui.journal_progress.text.find("Reach the unregistered case") == -1:
		_fail("The reloaded journal showed a stale objective.")
		return
	state.persistence_enabled = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_save))
	print("STORY_GUIDE_SMOKE_OK: journal, three hints, reset, Wick, story stages and checkpoint reload")
	quit(0)


func _expect(state: Node, expected: String) -> bool:
	var actual: Dictionary = StoryGuide.current(state)
	if actual["id"] == expected:
		return true
	_fail("Expected objective '%s', got '%s'." % [expected, actual["id"]])
	return false


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _tap_key(code: int) -> void:
	Input.parse_input_event(_key(code))
	await process_frame
	var release := _key(code)
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _fail(message: String) -> void:
	push_error("STORY_GUIDE_SMOKE_FAIL: " + message)
	quit(1)
