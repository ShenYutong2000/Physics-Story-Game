extends SceneTree
## Render the Chapter I control walkway at both supported window sizes.

const CONTROL: PackedScene = preload("res://scenes/castle_control_walkway.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-step3"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags["control_walkway_intro_seen"] = true
	if not state.transition_castle_pose(&"tilted"):
		quit(1)
		return
	var control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	if not await _capture("control-walkway-tilted-1672x941.png", Vector2i(1672, 941)):
		quit(1)
		return
	if not await _capture("control-walkway-tilted-1280x720.png", Vector2i(1280, 720)):
		quit(1)
		return
	if not state.transition_castle_pose(&"inverted"):
		quit(1)
		return
	control.queue_free()
	await process_frame
	control = CONTROL.instantiate()
	root.add_child(control)
	current_scene = control
	if not await _capture("control-walkway-inverted-preview.png", Vector2i(1672, 941)):
		quit(1)
		return
	print("PHASE2_STEP3_CAPTURE_OK")
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
