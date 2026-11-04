extends SceneTree
## Step 3: exercise one playable hall close-up and save review frames.

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const OUTPUT := "res://prologue-asset-pack-v1/hall-closeups-v2/review-captures/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.notes.clear()
	state.flags.clear()
	var hall: Node2D = HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	hall._unhandled_input(_key(KEY_ENTER))
	var kath: CharacterBody2D = hall.get_node("Kath")
	var ui: CanvasLayer = hall.get_node("HallUI")
	var focus: CanvasLayer = hall.get_node("HallPropFocus")
	kath.position.x = 120.0
	await _tap(KEY_E)
	if hall.mode != &"focus" or not focus.is_open() or kath.controls_enabled or state.has_note(&"archive-door"):
		_fail("Opening E should show the close-up without operating the door.")
		return
	await create_timer(0.3).timeout
	if focus.selected_action() != &"secure_door_bolt" or ui.journal.visible or ui.pause_menu.visible:
		_fail("The door action or modal ownership is incorrect.")
		return
	if not await _capture("interactive-door-before"):
		return
	hall._unhandled_input(_key(KEY_J))
	if hall.mode != &"focus" or ui.journal.visible:
		_fail("J opened the journal over the prop close-up.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if hall.mode != &"roam" or state.has_note(&"archive-door") or bool(state.flags.get("hall_door_latched", false)):
		_fail("Esc from an untouched close-up wrote progress or kept Kath locked.")
		return
	await _tap(KEY_E)
	await create_timer(0.3).timeout
	await _tap(KEY_E)
	if not bool(state.flags.get("hall_door_latched", false)) or not state.has_note(&"archive-door") or not focus.completed:
		_fail("Operating E did not change the image and record the door exactly once.")
		return
	await create_timer(0.33).timeout
	if not await _capture("interactive-door-after"):
		return
	await _tap(KEY_E)
	if state.notes.size() != 1:
		_fail("Repeated operation duplicated the note.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if hall.mode != &"dialogue" or focus.is_open():
		_fail("Closing the operated prop did not show Kath's reaction.")
		return
	hall._unhandled_input(_key(KEY_ENTER))
	if hall.mode != &"roam":
		_fail("The response did not return to exploration.")
		return
	await _tap(KEY_E)
	await create_timer(0.3).timeout
	if not focus.completed or focus.selected_action() != &"" or state.notes.size() != 1:
		_fail("Reopening did not restore the secured state.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.2).timeout
	if hall.mode != &"roam" or ui.journal.visible or ui.pause_menu.visible:
		_fail("Returning from a repeat visit left an overlapping modal.")
		return
	print("HALL_FOCUS_SMOKE_OK: open, cancel, operate, restore, modal isolation, both review sizes")
	hall.queue_free()
	await process_frame
	quit(0)


func _capture(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		root.size = resolution
		for i in 5:
			await process_frame
		var frame: Image = root.get_texture().get_image()
		if frame == null:
			_fail("No renderer texture is available for the review capture.")
			return false
		if frame.get_size() != resolution:
			frame.resize(resolution.x, resolution.y)
		var filename := OUTPUT + "%s-%dx%d.png" % [prefix, resolution.x, resolution.y]
		if frame.save_png(ProjectSettings.globalize_path(filename)) != OK:
			_fail("Could not save review capture: " + filename)
			return false
	return true


func _tap(code: int) -> void:
	Input.parse_input_event(_key(code))
	await process_frame
	var release := _key(code)
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _fail(message: String) -> void:
	push_error("HALL_FOCUS_SMOKE_FAIL: " + message)
	quit(1)
