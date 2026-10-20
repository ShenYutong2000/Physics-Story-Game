extends SceneTree
## Visual acceptance captures for the lower passage and real-down observation.

const CONTROL: PackedScene = preload("res://scenes/castle_control_walkway.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-step2"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"upright"
	state.transition_castle_pose(&"tilted")
	state.transition_castle_pose(&"inverted")
	state.flags["control_inversion_complete"] = true
	state.flags["control_walkway_intro_seen"] = true
	var control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	control.kath.position.x = 600.0
	if not await _capture("01-control-lower-hatch-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("01-control-lower-hatch-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	control._inspect(control.lower_service_hatch)
	await process_frame
	var room = current_scene
	if room == null or room.name != "Chapter1InvertedRoom":
		push_error("Capture did not enter official inverted room.")
		quit(1)
		return
	if not await _capture("02-room-intro-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	room._close_overlay()
	if not await _capture("02-room-entry-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("02-room-entry-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	room.kath.position.x = 860.0
	if not await _capture("03-room-observation-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	room.kath.position.x = 1410.0
	if not await _capture("04-room-ladder-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	print("PHASE3_STEP2_CAPTURE_OK: lower hatch, entry, water/chain and shaft ladder")
	quit(0)


func _capture(name: String, resolution: Vector2i) -> bool:
	root.size = resolution
	for i in 5:
		await process_frame
	var frame := root.get_texture().get_image()
	if frame == null:
		push_error("Could not read screenshot %s." % name)
		return false
	var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(folder)
	var error := frame.save_png(folder.path_join(name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [name, error])
		return false
	return true
