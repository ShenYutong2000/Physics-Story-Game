extends SceneTree
## Capture the observatory at design and scaled resolution for visual review.

const ROOM: PackedScene = preload("res://scenes/chapter1_observatory_preview.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-step7"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var room := ROOM.instantiate()
	root.add_child(room)
	current_scene = room
	room.get_node("PreviewHint").visible = false
	if not await _capture("observatory-restored-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("observatory-restored-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	room.get_node("Kath").position.x = 400.0
	room.set_drawer_open(true)
	if not await _capture("observatory-open-drawer-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	room.show_document(0)
	if not await _capture("observatory-work-record-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("observatory-work-record-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	room.close_document()
	room.set_telescope_angle(-6.0)
	if not await _capture("observatory-telescope-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	print("PHASE2_STEP7_CAPTURE_OK")
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
