extends SceneTree
## Step 6: the east key is moved, its tag is revealed, and the state survives a checkpoint.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const HALL_PATH := "res://scenes/library_hall.tscn"
const SAVE_PATH := "res://tests/_hall_keys_checkpoint.json"
const OUTPUT := "res://prologue-asset-pack-v1/hall-closeups-v2/review-captures/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.persistence_enabled = false
	state.save_path_override = SAVE_PATH
	state.notes.clear()
	state.flags.clear()
	var hall: Node2D = await _new_hall()
	if hall.key_rack_world.east_key_sorted or hall.nearest_hotspot(1370.0) != hall.get_node("DutyKeys"):
		_fail("The unsorted rack was not reachable in the hall.")
		return
	hall.kath.position.x = 760.0
	if not await _capture("interactive-keys-hall-before"):
		return
	hall.kath.position.x = 1370.0
	await _tap(KEY_E)
	await create_timer(0.3).timeout
	if hall.mode != &"focus" or hall.focus.selected_action() != &"sort_duty_key" or hall.kath.controls_enabled or hall.focus.tag_card.visible:
		_fail("The east-key focus was not interactive and exclusive.")
		return
	if not await _capture("interactive-keys-before"):
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if state.flags.get("hall_east_key_sorted", false) or state.has_note(&"duty-keys") or hall.key_rack_world.east_key_sorted:
		_fail("Esc before moving the key marked it sorted.")
		return
	await _tap(KEY_E)
	await create_timer(0.3).timeout
	await _tap(KEY_E)
	await create_timer(0.55).timeout
	if not state.flags.get("hall_east_key_sorted", false) or not state.has_note(&"duty-keys") \
		or state.notes.size() != 1 or not hall.key_rack_world.east_key_sorted or not hall.focus.completed \
		or not hall.focus.tag_card.visible or hall.focus.tag_label.text != "OBSERVATORY\nCASTLE":
		_fail("Moving the east key did not update the close-up, world rack, tag, and single note.")
		return
	if not await _capture("interactive-keys-after"):
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if hall.mode != &"dialogue":
		_fail("Kath did not react to the newly revealed key tag.")
		return
	hall._unhandled_input(_key(KEY_ENTER))
	hall.kath.position.x = 760.0
	if not await _capture("interactive-keys-hall-after"):
		return
	hall.queue_free()
	await process_frame
	hall = await _new_hall()
	if not hall.key_rack_world.east_key_sorted or state.notes.size() != 1:
		_fail("Re-entering the hall reset the rack or duplicated the note.")
		return
	hall.kath.position.x = 1370.0
	await _tap(KEY_E)
	await create_timer(0.3).timeout
	if not hall.focus.completed or hall.focus.selected_action() != &"" or not hall.focus.tag_card.visible:
		_fail("Reopening the sorted rack lost its completed state.")
		return
	await _tap(KEY_E)
	if state.notes.size() != 1:
		_fail("Repeated E duplicated the duty-key entry.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	state.persistence_enabled = true
	if not state.save_checkpoint(HALL_PATH):
		_fail("The duty-key state could not be checkpointed.")
		return
	hall.queue_free()
	await process_frame
	state.notes.clear()
	state.flags.clear()
	if not state.resume_checkpoint():
		_fail("The duty-key checkpoint could not be resumed.")
		return
	await process_frame
	await process_frame
	hall = current_scene
	if hall == null or not hall.key_rack_world.east_key_sorted or not state.has_note(&"duty-keys"):
		_fail("The saved duty-key arrangement was not restored.")
		return
	state.persistence_enabled = false
	_cleanup_save()
	print("HALL_KEYS_SMOKE_OK: proximity, cancel, move and tag reveal, repeat, scene revisit, checkpoint restore")
	quit(0)


func _new_hall() -> Node2D:
	var hall: Node2D = HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	if hall.mode == &"dialogue":
		hall._close_dialogue(false)
	return hall


func _capture(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		root.size = resolution
		for i in 5:
			await process_frame
		var frame: Image = root.get_texture().get_image()
		if frame == null:
			_fail("No renderer texture is available for the key-rack review capture.")
			return false
		if frame.get_size() != resolution:
			frame.resize(resolution.x, resolution.y)
		var filename := OUTPUT + "%s-%dx%d.png" % [prefix, resolution.x, resolution.y]
		if frame.save_png(ProjectSettings.globalize_path(filename)) != OK:
			_fail("Could not save key-rack review capture: " + filename)
			return false
	return true


func _tap(code: int) -> void:
	Input.parse_input_event(_key(code))
	await process_frame
	Input.parse_input_event(_release(code))
	await process_frame


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _release(code: int) -> InputEventKey:
	var event := _key(code)
	event.pressed = false
	return event


func _cleanup_save() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))
	root.get_node("PrologueState").save_path_override = ""


func _fail(message: String) -> void:
	push_error("HALL_KEYS_SMOKE_FAIL: " + message)
	quit(1)
