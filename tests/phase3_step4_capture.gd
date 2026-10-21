extends SceneTree
## Review the official rescue trip at both supported window sizes.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-step4"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	var shaft = SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	await process_frame
	shaft.kath.position.x = 710.0
	if not await _capture_pair("01-shaft-survey"):
		quit(1)
		return
	state.flags["shaft_erin_contacted"] = true
	state.flags["shaft_rig_inspected"] = true
	state.flags["shaft_tool_goal"] = true
	state.flags["shaft_tools_loaded"] = true
	shaft._update_rig_visuals()
	if not await _capture_pair("02-tools-loaded"):
		quit(1)
		return
	shaft.kath.position.x = 450.0
	shaft.basket_progress = 1.0
	state.flags["shaft_basket_progress"] = 1.0
	shaft._update_rig_visuals()
	shaft._set_mode(&"winch")
	shaft.ui.show_shaft_winch(1.0, false)
	if not await _capture_pair("03-tools-at-erin"):
		quit(1)
		return
	shaft._unhandled_input(_key(KEY_E))
	if not await _capture_pair("04-erin-receives"):
		quit(1)
		return
	shaft._close_overlay()
	state.flags["shaft_rail_removed"] = true
	state.flags["shaft_tool_trip_complete"] = true
	shaft.basket_progress = 0.0
	state.flags["shaft_basket_progress"] = 0.0
	shaft._update_rig_visuals()
	if not await _capture_pair("05-open-rail"):
		quit(1)
		return
	print("PHASE3_STEP4_CAPTURE_OK: survey, loading, lift and open rail at both resolutions")
	quit(0)


func _capture_pair(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		var name := "%s-%dx%d.png" % [prefix, resolution.x, resolution.y]
		if not await _capture(name, resolution):
			return false
	return true


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _capture(name: String, resolution: Vector2i) -> bool:
	root.size = resolution
	for i in 5:
		await process_frame
	var frame: Image = root.get_texture().get_image()
	if frame == null:
		push_error("No rendered frame available for " + name)
		return false
	var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(folder)
	var error := frame.save_png(folder.path_join(name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [name, error])
		return false
	return true
