extends SceneTree
## Observatory art shell, readable document panel, and story-state isolation.

const ROOM: PackedScene = preload("res://scenes/chapter1_observatory_preview.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	var pose_before: StringName = state.castle_pose
	var notes_before: int = state.notes.size()
	var flags_before: Dictionary = state.flags.duplicate(true)
	var room := ROOM.instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	var kath: CharacterBody2D = room.get_node("Kath")
	if kath.floor_y != room.FLOOR_Y or kath.left_limit != room.WALK_MIN_X or kath.right_limit != room.WALK_MAX_X:
		_fail("Kath cannot traverse the reserved observatory floor.")
		return
	if room.get_node("FarRestoredExterior").z_index >= room.get_node("ArchiveArchitecture").z_index or room.get_node("FrontParapet").z_index <= kath.z_index:
		_fail("The observatory layer order is incorrect.")
		return
	if room.get_node("RestoredWingEntry").position.y != room.FLOOR_Y:
		_fail("The reserved restored-wing entrance is off the walking plane.")
		return
	if room.get_node("ArchiveDrawer").visible:
		_fail("The archive drawer starts open.")
		return
	room.set_drawer_open(true)
	if not room.get_node("ArchiveDrawer").visible:
		_fail("The drawer does not have a distinct open visual.")
		return
	for index in 3:
		room.show_document(index)
		if not room.get_node("DocumentModal").visible or kath.controls_enabled or room.get_node("DocumentModal/DocumentTitle").text.is_empty() or room.get_node("DocumentModal/DocumentBody").text.is_empty():
			_fail("Archive document %d lacks readable engine-rendered text or modal control." % index)
			return
	room.close_document()
	if room.get_node("DocumentModal").visible or not kath.controls_enabled:
		_fail("Closing a document does not restore walking.")
		return
	room.set_telescope_angle(-6.0)
	if not is_equal_approx(room.get_node("TelescopePivot").rotation_degrees, -6.0):
		_fail("The optical tube cannot move separately from its mount.")
		return
	if state.castle_pose != pose_before or state.notes.size() != notes_before or state.flags != flags_before:
		_fail("The art preview changed official story state.")
		return
	print("PHASE2_STEP7_SMOKE_OK: floor, depth, telescope, drawer, three records, state isolation")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
