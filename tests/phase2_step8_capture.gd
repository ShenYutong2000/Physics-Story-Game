extends SceneTree
## Save a compact visual review of the independent room tour and edge prompts.

const TOUR: PackedScene = preload("res://scenes/chapter1_scene_tour.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-step8"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tour := TOUR.instantiate()
	root.add_child(tour)
	current_scene = tour
	if not await _capture("01-control-walkway-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	tour.active_room.get_node("Kath").position.x = tour.NEXT_EXIT_X[0]
	if not await _capture("01-control-walkway-exit-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	for i in range(1, 5):
		tour.show_room(i, i - 1)
		var name: String = "%02d-%s-1280x720.png" % [i + 1, String(tour.NAMES[i]).to_lower().replace(" ", "-")]
		if not await _capture(name, Vector2i(1280, 720)):
			quit(1)
			return
	tour.active_room.get_node("Kath").position.x = tour.PREVIOUS_EXIT_X[4]
	if not await _capture("05-observatory-return-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	print("PHASE2_STEP8_CAPTURE_OK")
	quit(0)


func _capture(name: String, resolution: Vector2i) -> bool:
	root.size = resolution
	for i in 6:
		await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("No renderer image for %s." % name)
		return false
	var destination := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(destination)
	var error := image.save_png(destination.path_join(name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [name, error])
		return false
	return true
