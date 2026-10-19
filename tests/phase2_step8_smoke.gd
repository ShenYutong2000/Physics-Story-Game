extends SceneTree
## Check the independent five-scene route, both travel directions and story-state isolation.

const TOUR: PackedScene = preload("res://scenes/chapter1_scene_tour.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	var pose_before: StringName = state.castle_pose
	var notes_before: Array = state.notes.duplicate(true)
	var flags_before: Dictionary = state.flags.duplicate(true)
	var spawn_before: StringName = state.pending_spawn_tag
	var tour := TOUR.instantiate()
	root.add_child(tour)
	current_scene = tour
	await process_frame
	if tour.room_index != 0 or tour.get_node("RoomHost").get_child_count() != 1:
		_fail("The tour did not begin at one control deck.")
		return
	if state.flags.has("control_walkway_intro_seen"):
		_fail("The preview ran the official control-walkway story script.")
		return
	var control: Node2D = tour.active_room
	control.set_preview_pose(&"inverted")
	if state.castle_pose != pose_before:
		_fail("Changing the preview pose advanced the official castle pose.")
		return
	var first_kath: CharacterBody2D = control.get_node("Kath")
	first_kath.position.x = 430.0
	var key_e := InputEventKey.new()
	key_e.physical_keycode = KEY_E
	key_e.pressed = true
	Input.parse_input_event(key_e)
	await process_frame
	if tour.room_index != 0:
		_fail("E traveled away from the control deck exit.")
		return
	first_kath.position.x = tour.NEXT_EXIT_X[0]
	if tour.nearby_exit_target() != 1:
		_fail("Control deck right exit did not select the inverted room.")
		return
	Input.parse_input_event(key_e)
	await process_frame
	await process_frame
	if tour.room_index != 1 or tour.get_node("RoomHost").get_child_count() != 1:
		_fail("The control-deck E transition did not load exactly one inverted room.")
		return
	if absf(tour.active_room.get_node("Kath").position.x - tour.SPAWN_FROM_PREVIOUS[1]) > 0.1:
		_fail("Forward birth point is missing or overlaps the destination exit.")
		return
	for i in range(2, 5):
		tour.active_room.get_node("Kath").position.x = tour.NEXT_EXIT_X[i - 1]
		Input.parse_input_event(key_e)
		await process_frame
		await process_frame
		if not _room_ok(tour, i):
			return
	if tour.nearby_exit_target() != -1:
		_fail("The observatory immediately retriggers the return exit after spawning.")
		return
	tour.active_room.set_drawer_open(true)
	var observatory: Node2D = tour.active_room
	for i in range(3, -1, -1):
		tour.active_room.get_node("Kath").position.x = tour.PREVIOUS_EXIT_X[i + 1]
		Input.parse_input_event(key_e)
		await process_frame
		await process_frame
		if not _room_ok(tour, i):
			return
	if tour.active_room != control or control.preview_pose != &"inverted":
		_fail("Returning to the control deck did not preserve local art-preview state.")
		return
	tour.show_room(4, 3)
	await process_frame
	if tour.active_room != observatory or not observatory.drawer_open:
		_fail("Returning to the observatory lost its local drawer preview.")
		return
	if state.castle_pose != pose_before or state.notes != notes_before or state.flags != flags_before or state.pending_spawn_tag != spawn_before:
		_fail("Five-room preview changed official story state.")
		return
	print("PHASE2_STEP8_SMOKE_OK: five rooms, safe spawns, E gate, round trip, cached art state, story isolation")
	quit(0)


func _room_ok(tour: Node2D, expected_index: int) -> bool:
	if tour.room_index != expected_index or tour.get_node("RoomHost").get_child_count() != 1:
		_fail("Room %d was not the only active room." % expected_index)
		return false
	var kath: CharacterBody2D = tour.active_room.get_node("Kath")
	if kath.position.x < kath.left_limit or kath.position.x > kath.right_limit or not is_equal_approx(kath.position.y, kath.floor_height_at(kath.position.x)):
		_fail("Room %d spawned Kath outside the safe foot line." % expected_index)
		return false
	if tour.active_room.get_node_or_null("Wick") == null:
		_fail("Room %d has no Wick." % expected_index)
		return false
	if tour.nearby_exit_target() >= 0:
		_fail("Room %d spawned Kath inside a transition trigger." % expected_index)
		return false
	return true


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
