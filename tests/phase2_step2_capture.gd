extends SceneTree
## Captures the isolated Chapter I character and fixture review scene.

const PREVIEW: PackedScene = preload("res://scenes/chapter1_character_preview.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-step2"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var preview = PREVIEW.instantiate()
	root.add_child(preview)
	current_scene = preview
	if not await _capture("characters-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	preview.get_node("Erin").set_repairing(true)
	if not await _capture("erin-repair-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	preview.get_node("Erin").set_repairing(false)
	preview.get_node("Erin").set_walking(true)
	for i in 15:
		await process_frame
	if not await _capture("erin-walk-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	print("PHASE2_STEP2_CAPTURE_OK")
	quit(0)


func _capture(name: String, resolution: Vector2i) -> bool:
	root.size = resolution
	for i in 6:
		await process_frame
	var image := root.get_texture().get_image()
	if image == null:
		push_error("The renderer provided no image for %s." % name)
		return false
	var output_dir := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(output_dir)
	var error := image.save_png(output_dir.path_join(name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [name, error])
		return false
	return true
