extends SceneTree
## Review frames for the first checkpoint of the passenger rescue.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-step6a"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	for flag in ["shaft_rig_inspected", "shaft_tools_loaded", "shaft_rail_removed", "shaft_tool_trip_complete", "shaft_passenger_rethread_complete", "shaft_empty_test_complete"]:
		state.flags[flag] = true
	state.flags["shaft_basket_progress"] = 1.0
	var shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	shaft.basket_progress = 0.62
	state.flags["shaft_basket_progress"] = 0.62
	shaft._update_rig_visuals()
	shaft._set_mode(&"winch")
	shaft.ui.show_shaft_winch(0.62, true, true, &"passenger_raise")
	if not await _capture_pair("00-full-lift-winch"):
		quit(1)
		return
	shaft._close_overlay()
	shaft.basket_progress = 1.0
	state.flags["shaft_basket_progress"] = 1.0
	shaft.kath.position.x = 790.0
	shaft._update_rig_visuals()
	if not await _capture_pair("01-empty-at-upper-ledge"):
		quit(1)
		return
	shaft._inspect(shaft.speaking_tube)
	shaft._unhandled_input(_key(KEY_ENTER))
	if not await _capture_pair("02-upper-dock-and-open-gate"):
		quit(1)
		return
	print("PHASE3_STEP6A_CAPTURE_OK: empty upper arrival and dock in two resolutions")
	quit(0)


func _capture_pair(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		root.size = resolution
		for i in 5:
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
