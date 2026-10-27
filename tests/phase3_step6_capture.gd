extends SceneTree
## Two-resolution review frames for the occupied rescue.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-step6"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	for flag in ["shaft_rig_inspected", "shaft_tools_loaded", "shaft_rail_removed", "shaft_tool_trip_complete", "shaft_passenger_rethread_complete", "shaft_empty_test_complete", "shaft_erin_aboard", "shaft_upper_dock_locked"]:
		state.flags[flag] = true
	state.flags["shaft_basket_progress"] = 1.0
	state.flags["shaft_rescue_phase"] = &"load_tension"
	var shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	shaft.kath.position.x = 450.0
	shaft._set_mode(&"winch")
	shaft.ui.show_shaft_winch(1.0, true, true, &"load_tension")
	if not await _capture_pair("01-erin-aboard-tension"):
		quit(1)
		return
	shaft._close_overlay()
	state.flags["shaft_load_preload"] = 1.0
	state.flags["shaft_load_tensioned"] = true
	state.flags["shaft_brake_hold_observed"] = true
	shaft._update_rig_visuals()
	shaft._set_mode(&"load_check")
	var checked: Array[StringName] = [&"rope", &"anchor"]
	shaft.ui.show_shaft_load_check(checked, 2)
	if not await _capture_pair("02-loaded-checks"):
		quit(1)
		return
	shaft._close_overlay()
	state.flags["shaft_load_verified"] = true
	state.flags["shaft_upper_dock_locked"] = false
	state.flags["shaft_rescue_phase"] = &"passenger_descent"
	state.flags["shaft_basket_progress"] = 0.5
	shaft.basket_progress = 0.5
	shaft.descent_speed = 0.07
	shaft._update_rig_visuals()
	shaft._set_mode(&"winch")
	shaft.ui.show_shaft_winch(0.5, true, true, &"passenger_descent", 0.07)
	if not await _capture_pair("03-controlled-descent"):
		quit(1)
		return
	shaft._close_overlay()
	state.flags["shaft_lower_arrived"] = true
	state.flags["shaft_lower_dock_locked"] = true
	state.flags["shaft_rescue_phase"] = &"lower_docked"
	state.flags["shaft_basket_progress"] = 0.0
	shaft.basket_progress = 0.0
	shaft.kath.position.x = 760.0
	shaft._update_rig_visuals()
	if not await _capture_pair("04-lower-docked"):
		quit(1)
		return
	state.flags["shaft_rescue_complete"] = true
	state.flags["shaft_rescue_phase"] = &"rescued"
	shaft._update_rig_visuals()
	if not await _capture_pair("05-erin-rescued"):
		quit(1)
		return
	print("PHASE3_STEP6_CAPTURE_OK: occupied rig, checks, descent, dock and rescue")
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
