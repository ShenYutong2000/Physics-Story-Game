extends SceneTree
## Check title and Continue readability at both supported window sizes.

const TITLE: PackedScene = preload("res://scenes/title_screen.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-step7"
const TEST_SAVE := "user://phase3-step7-title-capture.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.save_path_override = TEST_SAVE
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	var title = TITLE.instantiate()
	root.add_child(title)
	current_scene = title
	await process_frame
	if not await _capture_pair("01-new-game"):
		quit(1)
		return
	state.persistence_enabled = true
	state.save_checkpoint("res://scenes/chapter1_engine_room.tscn")
	state.persistence_enabled = false
	var menu = TITLE.instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	if not menu.has_save or not await _capture_pair("02-continue"):
		quit(1)
		return
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SAVE))
	state.save_path_override = ""
	print("PHASE3_STEP7_TITLE_CAPTURE_OK: New Game and Continue at both resolutions")
	quit(0)


func _capture_pair(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		root.size = resolution
		for i in 8:
			await process_frame
		var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
		DirAccess.make_dir_recursive_absolute(folder)
		var path := folder.path_join("%s-%dx%d.png" % [prefix, resolution.x, resolution.y])
		if root.get_texture().get_image().save_png(path) != OK:
			push_error("Could not save " + path)
			return false
	return true
