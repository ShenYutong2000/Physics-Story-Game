extends SceneTree
## Verify fixed/movable layers and isolated preview-state changes.

const ENGINE: PackedScene = preload("res://scenes/chapter1_engine_room_preview.tscn")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var story_state: Node = root.get_node("PrologueState")
	var pose_before: StringName = story_state.castle_pose
	var note_count_before: int = story_state.notes.size()
	var flags_before: Dictionary = story_state.flags.duplicate(true)
	var room := ENGINE.instantiate()
	root.add_child(room)
	current_scene = room
	await process_frame
	var kath: CharacterBody2D = room.get_node("Kath")
	if not is_equal_approx(kath.position.y, room.FLOOR_Y) or kath.left_limit != room.WALK_MIN_X or kath.right_limit != room.WALK_MAX_X:
		_fail("Kath is not constrained to the operator deck.")
		return
	if room.get_node("FarFixedTower").z_index >= room.get_node("FixedEngineRoom").z_index:
		_fail("The fixed tower is in front of the interior machinery.")
		return
	if room.get_node("FrontGuardrail").z_index <= kath.z_index:
		_fail("The near guardrail cannot cover Kath.")
		return
	if not is_equal_approx(room.get_node("WindowWingPivot").rotation, story_state.castle_pose_angle_radians()):
		_fail("The distant wing does not initially read the shared castle pose.")
		return
	if room.get_node("LowerServiceEntry").position.y != room.FLOOR_Y or room.get_node("RestoredWingExit").position.y != room.FLOOR_Y:
		_fail("Future passage thresholds do not align with the walking surface.")
		return
	room.set_preview_state(&"inverted", &"jammed")
	if not room.get_node("JamDebris").visible or room.get_node("StopSignal").texture != room.STOP_TEXTURE:
		_fail("The blocked repair state lacks its obstruction or warning.")
		return
	var blocked_x: float = room.get_node("NormalLinkage").position.x
	var lock_y: float = room.get_node("BackupLock").position.y
	room.set_preview_state(&"inverted", &"cleared")
	if room.get_node("JamDebris").visible or room.get_node("NormalLinkage").position.x <= blocked_x:
		_fail("Clearing the obstruction does not free the normal-position linkage.")
		return
	if room.get_node("BackupLock").position.y != lock_y:
		_fail("The independent backup lock released before restoration.")
		return
	room.set_preview_state(&"inverted", &"braked")
	if room.get_node("BrakeWheel").modulate.r < 0.99 or not room.get_node("BrakePawl").visible or room.get_node("BackupLock").position.y != lock_y:
		_fail("Braking state alters the wrong mechanism.")
		return
	room.set_preview_state(&"restored", &"restored")
	if room.get_node("StopSignal").texture != room.NORMAL_TEXTURE or room.get_node("BackupLock").position.y >= lock_y:
		_fail("The restored warning or backup-lock visual is incorrect.")
		return
	if not is_equal_approx(room.get_node("WindowWingPivot").rotation, story_state.castle_pose_angle_radians(&"restored")):
		_fail("The distant wing does not show the restored pose.")
		return
	if story_state.castle_pose != pose_before or story_state.notes.size() != note_count_before or story_state.flags != flags_before:
		_fail("The art preview changed official story state.")
		return
	print("PHASE2_STEP6_SMOKE_OK: walk, depth, fixed ring, pose view, repair layers, story isolation")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
