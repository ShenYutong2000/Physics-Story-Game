extends SceneTree
## Render the official on-site inversion at both supported window sizes.

const CONTROL: PackedScene = preload("res://scenes/castle_control_walkway.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-step1"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.flags["incident_complete"] = true
	state.flags["control_walkway_intro_seen"] = true
	state.transition_castle_pose(&"tilted")
	var control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	control.kath.position.x = 430.0
	if not await _capture("01-before-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("01-before-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	control._inspect(control.erin_station)
	for i in 3:
		control._advance_dialogue()
	control._inspect(control.position_dial)
	for i in 2:
		control._advance_dialogue()
	control._inspect(control.return_console)
	for i in 2:
		control._advance_dialogue()
	var deadline := Time.get_ticks_msec() + 12000
	while control.erin.position.x < 550.0 and Time.get_ticks_msec() < deadline:
		await process_frame
	if not await _capture("02-erin-stair-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	deadline = Time.get_ticks_msec() + 12000
	while control.erin.position.x < 950.0 and Time.get_ticks_msec() < deadline:
		await process_frame
	if not await _capture("02-erin-bridge-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	deadline = Time.get_ticks_msec() + 12000
	while control.castle_wing_pivot.rotation > -1.25 and Time.get_ticks_msec() < deadline:
		await process_frame
	if Time.get_ticks_msec() >= deadline:
		push_error("The wing never reached the mid-turn capture angle.")
		quit(1)
		return
	if not await _capture("02-moving-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	deadline = Time.get_ticks_msec() + 15000
	while state.castle_pose != &"inverted" and Time.get_ticks_msec() < deadline:
		await process_frame
	if state.castle_pose != &"inverted":
		push_error("The wing never completed inversion for the final capture.")
		quit(1)
		return
	if not await _capture("03-inverted-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("03-inverted-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	print("PHASE3_STEP1_CAPTURE_OK: before, continuous turn, inverted aftermath")
	quit(0)


func _capture(name: String, resolution: Vector2i) -> bool:
	root.size = resolution
	for i in 5:
		await process_frame
	var frame := root.get_texture().get_image()
	if frame == null:
		push_error("Could not read screenshot %s." % name)
		return false
	if frame.get_size() != resolution:
		var window_frame := Image.create_empty(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
		window_frame.fill(Color.BLACK)
		window_frame.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i.ZERO)
		frame = window_frame
	var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(folder)
	var error := frame.save_png(folder.path_join(name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [name, error])
		return false
	return true
