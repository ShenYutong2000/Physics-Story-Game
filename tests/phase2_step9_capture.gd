extends SceneTree
## Final phase-two visual audit: every room at both supported window sizes.

const TOUR: PackedScene = preload("res://scenes/chapter1_scene_tour.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-step9"
const ROOM_SLUGS := ["control-walkway", "inverted-room", "maintenance-shaft", "engine-room", "observatory"]
const REVIEW_X := [430.0, 360.0, 255.0, 840.0, 870.0]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var tour := TOUR.instantiate()
	root.add_child(tour)
	current_scene = tour
	for i in ROOM_SLUGS.size():
		if i > 0:
			tour.show_room(i, i - 1)
		var kath: CharacterBody2D = tour.active_room.get_node("Kath")
		kath.position = Vector2(REVIEW_X[i], kath.floor_height_at(REVIEW_X[i]))
		var wick: Node2D = tour.active_room.get_node("Wick")
		wick.position = kath.position + Vector2(-90, -225)
		if not await _capture("%02d-%s-1672x941.png" % [i + 1, ROOM_SLUGS[i]], Vector2i(1672, 941)):
			quit(1)
			return
		if not await _capture("%02d-%s-1280x720.png" % [i + 1, ROOM_SLUGS[i]], Vector2i(1280, 720)):
			quit(1)
			return
	print("PHASE2_STEP9_CAPTURE_OK: five rooms at 1672x941 and 1280x720")
	quit(0)


func _capture(name: String, resolution: Vector2i) -> bool:
	root.size = resolution
	for i in 6:
		await process_frame
	var frame := root.get_texture().get_image()
	if frame == null:
		push_error("No renderer image for %s." % name)
		return false
	# The 1672:941 design ratio produces a 1279-pixel content area in a
	# 1280x720 window. Preserve those pixels and include the 1-pixel pillarbox.
	if frame.get_size() != resolution:
		var window_frame := Image.create_empty(resolution.x, resolution.y, false, Image.FORMAT_RGBA8)
		window_frame.fill(Color.BLACK)
		window_frame.blit_rect(frame, Rect2i(Vector2i.ZERO, frame.get_size()), Vector2i.ZERO)
		frame = window_frame
	var destination := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(destination)
	var error := frame.save_png(destination.path_join(name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [name, error])
		return false
	return true
