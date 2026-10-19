extends SceneTree
## The art preview must remain walkable and independent of story state.

const ROOM: PackedScene = preload("res://scenes/chapter1_inverted_room_preview.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Node = root.get_node("PrologueState")
	var notes_before: int = state.notes.size()
	var pose_before: StringName = state.castle_pose
	var room := ROOM.instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	var kath: CharacterBody2D = room.get_node("Kath")
	if room.get_node("FarExterior").z_index >= room.get_node("RoomShell").z_index:
		_fail("The fixed exterior is in front of the room shell.")
		return
	if room.get_node("FrontParapet").z_index <= kath.z_index:
		_fail("The near parapet cannot occlude Kath.")
		return
	if not is_equal_approx(kath.position.y, 806.0) or kath.left_limit != 100.0 or kath.right_limit != 1470.0:
		_fail("Kath is not on the preview's continuous lower stone surface.")
		return
	var pipe: Sprite2D = room.get_node("SplitWaterPipe")
	var water: Sprite2D = room.get_node("FallingWater")
	var plumb: Sprite2D = room.get_node("PlumbChain")
	if pipe.texture == null or water.texture == null or plumb.texture == null:
		_fail("A separate gravity clue sprite is missing.")
		return
	if plumb.scale.y <= 0.0 or water.scale.y <= 0.0 or room.get_node("WallLadder").texture == null or room.get_node("FallenChandelier").texture == null:
		_fail("A downward-facing clue or access asset is missing.")
		return
	Input.action_press("move_right")
	for i in 15:
		await physics_frame
	Input.action_release("move_right")
	if kath.position.x <= 330.0 or not is_equal_approx(kath.position.y, 806.0):
		_fail("Kath could not walk along the inverted room's lower floor.")
		return
	if state.notes.size() != notes_before or state.castle_pose != pose_before:
		_fail("The art preview modified official story progress.")
		return
	print("PHASE2_STEP4_SMOKE_OK: layered room, downward clues, safe walk, untouched story")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
