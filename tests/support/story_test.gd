extends SceneTree
## Base class for the story tests under tests/.
##
## Each test extends this script and implements `_run()`. Run one test with
##   godot --headless --path . --script tests/<name>_test.gd
## or every test with tools/run_tests.ps1.
##
## Review screenshots are optional. Pass `-- --capture-dir=<absolute folder>`
## (without --headless) to save the frames a test marks with `_capture()`.
## Tests never write into the project folder.

const HALL_SCENE: PackedScene = preload("res://scenes/library_hall.tscn")
const REVIEW_SIZES := [Vector2i(1672, 941), Vector2i(1280, 720)]
## A close-up is usable this long after it opens, and gone this long after Esc.
const FOCUS_IN := 0.62
const FOCUS_OUT := 0.5
## Holding a key this long carries a hands-on slide all the way home.
const SLIDE_HOLD := 1.0

var state: Node
var capture_dir := ""


func _initialize() -> void:
	state = root.get_node("PrologueState")
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-dir="):
			capture_dir = argument.trim_prefix("--capture-dir=")
	call_deferred("_run")


func _run() -> void:
	push_error("%s does not implement _run()." % _test_name())
	quit(1)


func _test_name() -> String:
	return (get_script() as Script).resource_path.get_file().get_basename().to_upper()


func _fail(message: String) -> void:
	push_error("%s_FAIL: %s" % [_test_name(), message])
	quit(1)


func _pass(summary: String) -> void:
	print("%s_OK: %s" % [_test_name(), summary])
	quit(0)


func _reset_story() -> void:
	state.notes.clear()
	state.flags.clear()
	state.pending_spawn_tag = &""
	state.castle_pose = &"upright"


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


## Press and release a key through the real input pipeline.
func _tap(code: int) -> void:
	Input.parse_input_event(_key(code))
	await process_frame
	Input.parse_input_event(_release(code))
	await process_frame


## Hold a key on a room for a while, as a player would on a hands-on part.
func _hold_on(room: Node, code: int, seconds: float) -> void:
	room._unhandled_input(_key(code))
	await create_timer(seconds).timeout
	room._unhandled_input(_release(code))


func _mouse_button(position: Vector2, pressed: bool, button: int = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	event.position = position
	return event


## Press, drag in a few steps and release on a room.
func _drag_on(room: Node, from: Vector2, to: Vector2, release: bool = true) -> void:
	room._unhandled_input(_mouse_button(from, true))
	for step in range(1, 7):
		var motion := InputEventMouseMotion.new()
		motion.position = from.lerp(to, step / 6.0)
		room._unhandled_input(motion)
		await process_frame
	if release:
		room._unhandled_input(_mouse_button(to, false))


func _open_scene(scene: PackedScene) -> Node:
	var instance := scene.instantiate()
	root.add_child(instance)
	current_scene = instance
	await process_frame
	return instance


func _new_hall() -> Node2D:
	var hall: Node2D = await _open_scene(HALL_SCENE)
	if hall.mode == &"dialogue":
		hall._close_dialogue(false)
	return hall


## Render the current frame at both supported window sizes. Saves PNGs only
## when a capture folder was given; otherwise it just exercises both layouts.
func _capture(label: String) -> bool:
	# A minimised window renders nothing, so its captures would come back blank.
	if not capture_dir.is_empty() and DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_MINIMIZED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		for _frame in 3:
			await process_frame
	for resolution: Vector2i in REVIEW_SIZES:
		root.size = resolution
		for _frame in 5:
			await process_frame
		if capture_dir.is_empty():
			continue
		var frame: Image = root.get_texture().get_image()
		if frame == null:
			_fail("No rendered frame for review capture '%s'. Captures need a window, not --headless." % label)
			return false
		if frame.get_size() != resolution:
			frame.resize(resolution.x, resolution.y)
		var path := capture_dir.path_join("%s-%dx%d.png" % [label, resolution.x, resolution.y])
		DirAccess.make_dir_recursive_absolute(capture_dir)
		if frame.save_png(path) != OK:
			_fail("Could not save review capture: " + path)
			return false
	return true
