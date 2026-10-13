extends SceneTree

const HALL: PackedScene = preload("res://scenes/library_hall.tscn")
const UPPER: PackedScene = preload("res://scenes/upper_stacks.tscn")
const FLOOR_Y := 708.0
const CASE_X := 1012.0
const LADDER_START_X := 1198.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not root.has_node("PrologueState"):
		var test_state := Node.new()
		test_state.name = "PrologueState"
		test_state.set_script(load("res://scripts/prologue_state.gd"))
		root.add_child(test_state)
	var state: Node = root.get_node("PrologueState")
	state.notes.clear()
	state.flags.clear()
	state.pending_spawn_tag = &""
	var hall := HALL.instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	if state.upper_stacks_unlocked():
		_fail("The Hall did not keep the Upper Stacks locked before a machine reading.")
		return
	hall._close_dialogue(false)
	await process_frame
	hall._inspect(hall.get_node("UpperStacksEntry"))
	if hall.mode != &"dialogue":
		_fail("The early-entry reminder did not open.")
		return
	hall._close_dialogue(false)
	for note_id in state.HALL_NOTE_IDS:
		state.add_note_once(note_id, String(note_id), "Observation")
	state.flags["machine_baseline_recorded"] = true
	hall.kath.position.x = 1530.0
	await _tap_key(KEY_E)
	var upper = current_scene
	if upper == null or upper.name != "UpperStacks" or upper.kath.position.y != FLOOR_Y:
		_fail("The Hall did not enter the Upper Stacks at the correct floor height.")
		return
	if absf(upper.kath.animated_sprite.scale.y * 771.0 - 301.6) > 0.2 \
		or absf(upper.wick.moth.scale.y * 829.0 - 130.0) > 0.2:
		_fail("Kath or Wick lost the shared character scale.")
		return
	upper._close_dialogue(false)

	# Roof inspection, cancellable note additions, and the leak response.
	upper.kath.position.x = 1400.0
	upper._unhandled_input(_key(KEY_E))
	if upper.mode != &"dialogue" or not upper.leak_inspected:
		_fail("The roof seam did not produce its inspection dialogue.")
		return
	upper._close_dialogue(false)
	upper._unhandled_input(_key(KEY_E))
	if not state.flags.get("stacks_bucket_moved", false) or not state.has_note(&"leak-observation"):
		_fail("Moving the bucket did not persist its state and add one observation.")
		return
	upper._unhandled_input(_key(KEY_E))
	if state.notes.filter(func(note: Dictionary) -> bool: return note["id"] == &"leak-observation").size() != 1:
		_fail("Repeating the bucket interaction duplicated its note.")
		return
	upper._close_dialogue(false)

	# A misaligned ladder cannot reach the case; pushing and locking aligns it.
	upper.kath.position.x = LADDER_START_X - 72.0
	upper._unhandled_input(_key(KEY_E))
	if upper.kath.locomotion_mode != &"push":
		_fail("The rolling ladder did not enter push mode.")
		return
	Input.action_press("move_left")
	for i in 20:
		await physics_frame
	Input.action_release("move_left")
	await process_frame
	upper._unhandled_input(_key(KEY_E))
	if upper.kath.locomotion_mode != &"walk" or absf(upper.ladder.position.x - LADDER_START_X) < 1.0:
		_fail("Locking the ladder did not preserve its deliberately misaligned position.")
		return
	upper._unhandled_input(_key(KEY_E))
	if upper.kath.locomotion_mode != &"climb":
		_fail("A locked but misaligned ladder could not be climbed.")
		return
	Input.action_press("move_up")
	for i in 200:
		await physics_frame
	Input.action_release("move_up")
	upper._unhandled_input(_key(KEY_E))
	if upper.case_open:
		_fail("A horizontally misaligned ladder allowed the case to open.")
		return
	Input.action_press("move_down")
	for i in 200:
		await physics_frame
	Input.action_release("move_down")
	await process_frame
	if upper.kath.locomotion_mode != &"walk":
		_fail("Descending from a misaligned ladder did not return Kath to the floor.")
		return
	upper._unhandled_input(_key(KEY_E))
	if upper.kath.locomotion_mode != &"push":
		_fail("Kath could not unlock the misaligned ladder for repositioning.")
		return
	Input.action_press("move_left")
	for i in 55:
		await physics_frame
	Input.action_release("move_left")
	await process_frame
	if absf(upper.ladder.position.x - CASE_X) > 5.0:
		_fail("A/D or arrow movement did not roll the ladder beneath the case.")
		return
	upper._unhandled_input(_key(KEY_E))
	if upper.kath.locomotion_mode != &"walk" or absf(upper.ladder.position.x - CASE_X) > 5.0:
		_fail("Locking the aligned ladder did not preserve its position.")
		return
	upper._unhandled_input(_key(KEY_E))
	if upper.kath.locomotion_mode != &"climb":
		_fail("An aligned, locked ladder did not allow climbing.")
		return
	Input.action_press("move_up")
	for i in 120:
		await physics_frame
	Input.action_release("move_up")
	upper._unhandled_input(_key(KEY_E))
	if upper.case_open or upper.mode != &"roam":
		_fail("The box opened before Kath climbed high enough.")
		return
	var paused_height: float = upper.kath.position.y
	upper._unhandled_input(_key(KEY_ESCAPE))
	if upper.mode != &"paused" or upper.kath.locomotion_mode != &"climb" or upper.kath.position.y != paused_height:
		_fail("Pausing on the ladder changed Kath's climbing position.")
		return
	upper._unhandled_input(_key(KEY_ESCAPE))
	Input.action_press("move_up")
	for i in 20:
		await physics_frame
	Input.action_release("move_up")
	upper._unhandled_input(_key(KEY_E))
	if not upper.case_open or upper.case_sprite.frame != 1:
		_fail("The reachable wooden case did not open into its note state.")
		return
	upper._close_dialogue(false)
	upper._unhandled_input(_key(KEY_E))
	if upper.mode != &"paper" or not upper.ui.torn_page.visible:
		_fail("The note close-up did not open.")
		return
	upper._unhandled_input(_key(KEY_ESCAPE))
	if state.has_note(&"newton-note") or upper.case_sprite.frame != 1 or upper.mode != &"roam":
		_fail("Escaping the note close-up incorrectly collected or removed the page.")
		return
	upper._unhandled_input(_key(KEY_E))
	upper._unhandled_input(_key(KEY_ENTER))
	if not state.has_note(&"newton-note") or upper.case_sprite.frame != 2 or not state.flags.get("stacks_page_collected", false):
		_fail("Confirming the page did not record it and empty the case.")
		return
	if upper.mode != &"dialogue" or upper.dialogue_lines[0] != "This is my handwriting. I need to compare it with my notebook.":
		_fail("The one-time closing line did not play after collecting the page.")
		return
	upper._close_dialogue(false)
	upper._unhandled_input(_key(KEY_J))
	if upper.mode != &"journal" or not upper.ui.journal_progress.text.contains("UPPER STACKS  2 / 2"):
		_fail("Notes did not show the separate completed Upper Stacks checklist.")
		return
	upper._unhandled_input(_key(KEY_ENTER))
	if upper.mode != &"paper":
		_fail("The collected page could not be revisited from Notes.")
		return
	upper._unhandled_input(_key(KEY_ESCAPE))
	if upper.mode != &"journal":
		_fail("The journal page did not return to Notes when closed.")
		return
	upper._unhandled_input(_key(KEY_J))

	# Descend before leaving; re-entry restores all persistent room props.
	Input.action_press("move_down")
	for i in 200:
		await physics_frame
	Input.action_release("move_down")
	await process_frame
	if upper.kath.locomotion_mode != &"walk":
		_fail("Reaching floor level did not automatically end the climb.")
		return
	upper.kath.position.x = 500.0
	await _tap_key(KEY_E)
	hall = current_scene
	if hall == null or hall.name != "LibraryHall" or hall.kath.position.x != 1530.0:
		_fail("The Upper Stacks exit did not return to the Hall stairway.")
		return
	await _tap_key(KEY_E)
	upper = current_scene
	if upper == null or upper.name != "UpperStacks" or upper.mode != &"roam":
		_fail("Returning to the Upper Stacks replayed the introduction or blocked entry.")
		return
	if not state.flags.get("stacks_bucket_moved", false) or upper.case_sprite.frame != 2 \
		or absf(upper.ladder.position.x - CASE_X) > 5.0:
		_fail("Bucket, ladder, or page state was lost after a round trip.")
		return
	print("WEEK4_SMOKE_OK: gated entry, leak, ladder, climb, page cancel/collect/revisit, return state")
	upper.queue_free()
	state.queue_free()
	for i in 4:
		await process_frame
	quit(0)


func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _tap_key(code: int) -> void:
	Input.parse_input_event(_key(code))
	await process_frame
	var release := _key(code)
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame


func _fail(message: String) -> void:
	push_error("WEEK4_SMOKE_FAIL: " + message)
	quit(1)
