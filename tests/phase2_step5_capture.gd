extends SceneTree
## Visual review for both window sizes and both rig configurations.

const SHAFT: PackedScene = preload("res://scenes/chapter1_maintenance_shaft_preview.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-step5"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var shaft := SHAFT.instantiate()
	root.add_child(shaft)
	current_scene = shaft
	shaft.get_node("PreviewHint").visible = false
	if not await _capture("maintenance-shaft-tool-high-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("maintenance-shaft-tool-high-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	shaft.set_preview_state(&"passenger", &"high", &"person")
	if not await _capture("maintenance-shaft-passenger-high-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	shaft.set_preview_state(&"tool", &"low", &"tools")
	if not await _capture("maintenance-shaft-tool-low-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	shaft.set_preview_state(&"passenger", &"high", &"docked")
	if not await _capture("maintenance-shaft-docked-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	print("PHASE2_STEP5_CAPTURE_OK")
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
