extends SceneTree
## Review both ends of the official ladder passage at the two target sizes.

const ROOM: PackedScene = preload("res://scenes/chapter1_inverted_room.tscn")
const OUTPUT_DIR := "res://chapter1-assets/review-phase3-step3"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	state.flags.clear()
	state.notes.clear()
	state.castle_pose = &"inverted"
	state.flags["control_inversion_complete"] = true
	state.flags["inverted_room_intro_seen"] = true
	state.flags["castle_down_confirmed"] = true
	state.flags["room_ladder_checked"] = true
	var room = ROOM.instantiate()
	root.add_child(room)
	current_scene = room
	room.kath.position.x = 1455.0
	if not await _capture_pair("01-room-ladder"):
		quit(1)
		return
	room.kath.begin_climbing(1510.0, 475.0, 806.0, 475.0)
	if not await _capture_pair("02-room-hatch"):
		quit(1)
		return
	room._unhandled_input(_key(KEY_E))
	await process_frame
	var shaft = current_scene
	if shaft == null or shaft.name != "Chapter1MaintenanceShaft":
		push_error("Could not enter shaft for captures.")
		quit(1)
		return
	shaft._close_overlay()
	if not await _capture_pair("03-shaft-entry"):
		quit(1)
		return
	shaft.kath.position.x = 190.0
	if not await _capture_pair("04-shaft-return"):
		quit(1)
		return
	print("PHASE3_STEP3_CAPTURE_OK: ladder, hatch and shaft entry at both resolutions")
	quit(0)


func _capture_pair(prefix: String) -> bool:
	for resolution in [Vector2i(1672, 941), Vector2i(1280, 720)]:
		var name := "%s-%dx%d.png" % [prefix, resolution.x, resolution.y]
		if not await _capture(name, resolution):
			return false
	return true


func _capture(name: String, resolution: Vector2i) -> bool:
	root.size = resolution
	for i in 5:
		await process_frame
	var image: Image = root.get_texture().get_image()
	if image == null:
		push_error("No rendered frame available for %s. Use graphical Godot for captures." % name)
		return false
	var folder := ProjectSettings.globalize_path(OUTPUT_DIR)
	DirAccess.make_dir_recursive_absolute(folder)
	var error := image.save_png(folder.path_join(name))
	if error != OK:
		push_error("Could not save %s (error %d)." % [name, error])
		return false
	return true


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event
