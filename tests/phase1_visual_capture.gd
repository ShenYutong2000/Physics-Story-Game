extends SceneTree
## Run without --headless to render review images at both supported window sizes.

const ROAD: PackedScene = preload("res://scenes/service_road.tscn")
const CONTROL: PackedScene = preload("res://scenes/castle_control_walkway.tscn")
const OUTPUT_DIR := "res://../Phase1Review"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags["incident_complete"] = true
	state.flags["service_road_intro_seen"] = true
	state.flags["service_gate_open"] = true
	state.flags["control_walkway_intro_seen"] = true
	state.transition_castle_pose(&"tilted")
	state.pending_spawn_tag = &"from-machine-room"
	var road = ROAD.instantiate()
	root.add_child(road)
	current_scene = road
	road.kath.position.x = 1050.0
	road.kath.position.y = road.kath.floor_height_at(1050.0)
	if not await _capture("service-road-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("service-road-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	road._set_mode(&"chapter_end")
	road.ui.show_chapter_end()
	await create_timer(0.9).timeout
	if not await _capture("chapter-card-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	road.queue_free()
	await process_frame
	state.pending_spawn_tag = &"from-service-road"
	var control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	if not await _capture("control-walkway-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("control-walkway-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	control.ui.show_torn_page(true)
	if not await _capture("torn-page-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	print("PHASE1_VISUAL_CAPTURE_OK: " + ProjectSettings.globalize_path(OUTPUT_DIR))
	quit(0)


func _capture(file_name: String, resolution: Vector2i) -> bool:
	root.size = resolution
	for i in 6:
		await process_frame
	var screen := root.get_texture().get_image()
	if screen == null:
		push_error("The renderer did not provide a viewport image for %s." % file_name)
		return false
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var error := screen.save_png(output_dir.path_join(file_name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [file_name, error])
		return false
	return true
