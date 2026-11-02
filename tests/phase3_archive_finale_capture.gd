extends SceneTree
## Visual review of the three archive pages, repaired notebook and chapter card.

const OBSERVATORY: PackedScene = preload("res://scenes/chapter1_observatory.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-archive-finale"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"restored"
	state.flags["engine_restored"] = true
	state.flags["engine_intro_seen"] = true
	state.flags["observatory_arrival_seen"] = true
	var room = OBSERVATORY.instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	room.kath.position.x = 445.0
	room._inspect(room.records)
	room._unhandled_input(_key(KEY_ENTER))
	room._inspect(room.records)
	if not await _capture_pair("01-signed-work-record"):
		quit(1)
		return
	room._show_document(1)
	if not await _capture_pair("02-floating-isles-slip"):
		quit(1)
		return
	room._show_document(2)
	if not await _capture_pair("03-withdrawn-page"):
		quit(1)
		return
	room._unhandled_input(_key(KEY_ESCAPE))
	for document in room.DOCUMENTS:
		state.add_note_once(document["id"], document["note_title"], document["note_body"])
	state.flags["observatory_archive_complete"] = true
	room.kath.position.x = 1320.0
	room._inspect(room.worktable)
	if not await _capture_pair("04-repaired-notebook"):
		quit(1)
		return
	room._unhandled_input(_key(KEY_ENTER))
	for i in 3:
		if room.mode != &"dialogue":
			break
		room._unhandled_input(_key(KEY_ENTER))
	state.travel_to("res://scenes/chapter1_engine_room.tscn", &"from-observatory")
	await process_frame
	var engine = current_scene
	engine.kath.position.x = 495.0
	engine._inspect(engine.erin_conversation)
	for i in 5:
		if engine.mode != &"dialogue":
			break
		engine._unhandled_input(_key(KEY_ENTER))
	if engine.mode != &"chapter_end":
		push_error("The chapter card did not open for capture.")
		quit(1)
		return
	await create_timer(0.75).timeout
	if not await _capture_pair("05-chapter-complete"):
		quit(1)
		return
	print("PHASE3_ARCHIVE_FINALE_CAPTURE_OK: three pages, notebook and card at both resolutions")
	quit(0)


func _capture_pair(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		root.size = resolution
		for i in 6:
			await process_frame
		var frame: Image = root.get_texture().get_image()
		var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
		DirAccess.make_dir_recursive_absolute(folder)
		var name := "%s-%dx%d.png" % [prefix, resolution.x, resolution.y]
		if frame.save_png(folder.path_join(name)) != OK:
			push_error("Could not save " + name)
			return false
	return true


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event
