extends SceneTree
## Render the standalone art preview at both supported window sizes.

const ROOM: PackedScene = preload("res://scenes/chapter1_inverted_room_preview.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-step4"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var room := ROOM.instantiate()
	root.add_child(room)
	current_scene = room
	if not await _capture("inverted-room-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("inverted-room-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	room.get_node("Kath").position.x = 1290.0
	if not await _capture("inverted-room-right-walk-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	print("PHASE2_STEP4_CAPTURE_OK")
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
