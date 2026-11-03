extends SceneTree
## Archive evidence, notebook repair and Chapter I finale on the formal route.

const ENGINE: PackedScene = preload("res://scenes/chapter1_engine_room.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"restored"
	state.flags["shaft_rescue_complete"] = true
	state.flags["engine_restored"] = true
	state.flags["engine_intro_seen"] = true
	state.add_note_once(&"engine-wing-restored", "Wing restored", "The normal lock holds the wing at home.")
	var engine = ENGINE.instantiate()
	root.add_child(engine)
	current_scene = engine
	await process_frame
	engine._inspect(engine.observatory_exit)
	await process_frame
	var room = current_scene
	if room == null or room.name != "Chapter1Observatory":
		_fail("The restored engine room did not lead to the observatory.")
		return
	_dismiss(room)
	room._inspect(room.worktable)
	_dismiss(room)
	if room.ui.chapter1_notebook.visible or state.flags.get("observatory_page_stitched", false):
		_fail("The notebook could be stitched before the records were read.")
		return
	room._inspect(room.records)
	_dismiss(room)
	if not room.drawer.visible or not state.flags.get("observatory_drawer_open", false):
		_fail("Opening the shaken drawer did not change its visible state.")
		return
	room._inspect(room.records)
	room._unhandled_input(_key(KEY_ESCAPE))
	if state.has_note(&"observatory-work-record") or room.document_modal.visible:
		_fail("Esc recorded or left open a document.")
		return
	room._inspect(room.records)
	room._unhandled_input(_key(KEY_A))
	if room.document_index != 2 or not room.document_body.text.contains("Reason for withdrawal"):
		_fail("Left did not select the withdrawn page.")
		return
	room._unhandled_input(_key(KEY_ENTER))
	_dismiss(room)
	if not state.has_note(&"observatory-withdrawn") or state.has_note(&"observatory-work-record"):
		_fail("The wrong archive page was recorded.")
		return
	var notes_after_first: int = state.notes.size()
	room._inspect(room.engine_return)
	await process_frame
	engine = current_scene
	engine._inspect(engine.observatory_exit)
	await process_frame
	room = current_scene
	if not room.drawer.visible or state.notes.size() != notes_after_first or room.mode != &"roam":
		_fail("The archive drawer or notes changed on a round trip.")
		return
	room._inspect(room.records)
	room._unhandled_input(_key(KEY_ENTER))
	_dismiss(room)
	if not state.has_note(&"observatory-work-record") or not state.notes[-1]["body"].contains("Kath"):
		_fail("The signed Grand Archive work record was not preserved.")
		return
	if not String(state.notes[-1]["body"]).contains("mass") or not String(state.notes[-1]["body"]).contains("rope pull"):
		_fail("The work record did not distinguish the measured quantities.")
		return
	room._inspect(room.records)
	room._unhandled_input(_key(KEY_D))
	room._unhandled_input(_key(KEY_ENTER))
	_dismiss(room)
	if not state.flags.get("observatory_archive_complete", false) or not state.has_note(&"observatory-grand-archive-link"):
		_fail("All three documents did not establish the station connection.")
		return
	if state.has_note(&"observatory-page-stitched") or state.flags.get("chapter1_complete", false):
		_fail("Reading the archive prematurely finished the chapter.")
		return
	room._inspect(room.records)
	room._unhandled_input(_key(KEY_ENTER))
	if state.notes.size() != 5:
		_fail("Repeated document reading added a duplicate note.")
		return
	room._inspect(room.worktable)
	if room.mode != &"stitch" or not room.ui.chapter1_notebook.visible:
		_fail("The worktable did not open the notebook view after the records.")
		return
	room._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("observatory_page_stitched", false):
		_fail("Esc stitched the page without confirmation.")
		return
	room._inspect(room.worktable)
	room._unhandled_input(_key(KEY_ENTER))
	_dismiss(room)
	if not state.flags.get("observatory_page_stitched", false) or not state.has_note(&"observatory-page-stitched"):
		_fail("Enter did not restore the leaf to Kath's notebook.")
		return
	if not String(state.notes[-1]["body"]).contains("net force") or not String(state.notes[-1]["body"]).contains("friction"):
		_fail("Kath's final interpretation lacks an explicit condition or uncertainty.")
		return
	room._show_journal()
	if not room.ui.journal_progress.text.contains("OBSERVATORY  4 / 4"):
		_fail("The journal omitted the archive and notebook progress.")
		return
	room.ui.hide_modals()
	room._inspect(room.engine_return)
	await process_frame
	engine = current_scene
	if engine.nearest_hotspot(495.0) != engine.erin_conversation:
		_fail("Erin's final conversation did not unlock after the notebook was repaired.")
		return
	engine._inspect(engine.erin_conversation)
	engine._unhandled_input(_key(KEY_ESCAPE))
	if state.flags.get("chapter1_complete", false) or state.has_note(&"chapter1-departure"):
		_fail("Esc completed Erin's farewell dialogue.")
		return
	engine._inspect(engine.erin_conversation)
	_dismiss(engine)
	if not state.flags.get("chapter1_complete", false) or not state.has_note(&"chapter1-departure") or engine.mode != &"chapter_end" or not engine.ui.chapter1_end.visible:
		_fail("The farewell did not show the Chapter I completion card.")
		return
	var final_note_count: int = state.notes.size()
	engine._unhandled_input(_key(KEY_ENTER))
	engine._inspect(engine.erin_conversation)
	if engine.mode != &"chapter_end" or state.notes.size() != final_note_count:
		_fail("Reopening the completion card repeated story records.")
		return
	engine._unhandled_input(_key(KEY_ESCAPE))
	engine._inspect(engine.observatory_exit)
	await process_frame
	room = current_scene
	if not room.drawer.visible or not state.flags.get("observatory_page_stitched", false) or state.notes.size() != final_note_count:
		_fail("The completed archive did not persist on another visit.")
		return
	print("PHASE3_ARCHIVE_FINALE_OK: three documents, cancellation, round trips, notebook, Erin and chapter card")
	quit(0)


func _dismiss(scene: Node) -> void:
	for i in 6:
		if scene.mode != &"dialogue":
			return
		scene._unhandled_input(_key(KEY_ENTER))


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("PHASE3_ARCHIVE_FINALE_FAIL: " + message)
	quit(1)
