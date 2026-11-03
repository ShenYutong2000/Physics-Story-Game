extends SceneTree
## New Game, guarded replacement, checkpoint reload and damaged-save handling.

const TITLE: PackedScene = preload("res://scenes/title_screen.tscn")
const TEST_SAVE := "user://phase3-step7-checkpoint-test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.save_path_override = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE + ".tmp"))
	var title = TITLE.instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	if title.has_save or title.selection != 0:
		_fail("The first launch offered a nonexistent checkpoint.")
		return
	title._unhandled_input(_key(KEY_ENTER))
	await process_frame
	if current_scene == null or current_scene.scene_file_path != state.STORY_SCENES[0] or not state.has_checkpoint():
		_fail("New Game did not open the hall and create a checkpoint.")
		return
	state.castle_pose = &"inverted"
	for flag in ["control_inversion_complete", "castle_down_confirmed", "room_ladder_checked", "shaft_passenger_rethread_complete", "shaft_empty_test_complete", "shaft_erin_aboard", "shaft_upper_dock_locked", "shaft_load_verified"]:
		state.flags[flag] = true
	state.flags["shaft_rescue_phase"] = &"load_verified"
	state.flags["shaft_basket_progress"] = 1.0
	state.add_note_once(&"newton-note", "A torn leaf", "F = ma")
	state.add_note_once(&"shaft-occupied-load", "Load checked", "The basket held Erin.")
	state.chapter1_start_seconds = 40.0
	state.play_seconds = 64.0
	state.travel_to("res://scenes/chapter1_maintenance_shaft.tscn", &"from-inverted-room")
	await process_frame
	if current_scene == null or current_scene.scene_file_path != "res://scenes/chapter1_maintenance_shaft.tscn":
		_fail("The checkpoint route did not enter the shaft.")
		return
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"upright"
	state.play_seconds = 0.0
	state.persistence_enabled = false
	if not state.resume_checkpoint():
		_fail("A valid shaft checkpoint could not be resumed.")
		return
	await process_frame
	var shaft = current_scene
	if shaft == null or shaft.scene_file_path != "res://scenes/chapter1_maintenance_shaft.tscn" or state.castle_pose != &"inverted" or state.flags.get("shaft_rescue_phase") != &"load_verified" or absf(shaft.basket_progress - 1.0) > 0.001:
		_fail("The resumed shaft did not reconstruct its supported basket state.")
		return
	if state.notes.size() != 2 or not state.has_note(&"newton-note") or state.play_seconds < 64.0:
		_fail("Notes, order or play time were lost on resume.")
		return
	var time_before_pause: float = state.play_seconds
	shaft._set_mode(&"paused")
	state._process(5.1)
	if absf(state.play_seconds - time_before_pause) > 0.001:
		_fail("The play timer continued while paused.")
		return
	shaft._set_mode(&"roam")
	state.castle_pose = &"restored"
	state.flags["engine_restored"] = true
	state.flags["observatory_drawer_open"] = true
	state.flags["observatory_archive_complete"] = true
	state.flags["observatory_page_stitched"] = true
	state.flags["chapter1_complete"] = true
	state.travel_to("res://scenes/chapter1_observatory.tscn", &"from-engine-room")
	await process_frame
	if current_scene == null or not current_scene.drawer.visible:
		_fail("The late-chapter checkpoint did not restore the opened archive.")
		return
	state._process(0.5)
	if state.chapter1_finish_seconds < 64.0 or state.chapter1_elapsed_seconds() < 24.0:
		_fail("The chapter timer did not stop on completion.")
		return
	state.save_checkpoint(current_scene.scene_file_path)
	var menu = TITLE.instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	if not menu.has_save or menu.selection != 1:
		_fail("A valid checkpoint was not selected on the title screen.")
		return
	menu._unhandled_input(_key(KEY_UP))
	menu._unhandled_input(_key(KEY_ENTER))
	if not menu.confirming_new_game:
		_fail("New Game replaced an existing journey without confirmation.")
		return
	menu._unhandled_input(_key(KEY_ESCAPE))
	if menu.confirming_new_game or not state.has_checkpoint():
		_fail("Cancel did not preserve the existing checkpoint.")
		return
	var before_notes: int = state.notes.size()
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("{\"version\":999,\"scene\":\"res://scenes/library_hall.tscn\"}")
	file.close()
	if not state.has_checkpoint() or not state.resume_checkpoint() or state.notes.size() != before_notes:
		_fail("A damaged primary save did not recover the last valid backup.")
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE + ".bak"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE + ".tmp"))
	state.save_path_override = ""
	state.persistence_enabled = false
	print("PHASE3_STEP7_CHECKPOINT_OK: new game, shaft resume, archive state, timer and backup recovery")
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_STEP7_CHECKPOINT_FAIL: " + message)
	quit(1)
