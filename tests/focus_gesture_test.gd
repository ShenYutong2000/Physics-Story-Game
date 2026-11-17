extends "res://tests/support/story_test.gd"
## The hands-on slide: the bolt is stiff, then gives; mouse and keyboard reach the
## same result; nothing is lost by letting go early; the door only latches when
## the bolt is carried home.

const BOLT := Vector2(700, 600)


func _run() -> void:
	_reset_story()
	var hall: Node2D = await _new_hall()
	var focus: CanvasLayer = hall.focus
	hall._inspect(hall.archive_door)
	await create_timer(FOCUS_IN).timeout
	if focus.gesture == null or not focus.uses_gesture() or not focus.gesture.stuck:
		_fail("The door close shot did not offer a stiff hands-on bolt.")
		return

	# A click away from the bolt starts nothing and closes nothing.
	hall._unhandled_input(_mouse_button(Vector2(1100, 200), true))
	hall._unhandled_input(_mouse_button(Vector2(1100, 200), false))
	if hall.mode != &"focus" or focus.gesture.progress != 0.0:
		_fail("A click away from the bolt moved it or closed the close shot.")
		return

	# A small pull only strains the stiff bolt.
	await _drag_on(hall, BOLT, BOLT + Vector2(8, 0))
	if focus.gesture.progress != 0.0 or not focus.gesture.stuck or state.flags.get("hint_slide_seen", false):
		_fail("The bolt moved inside its stiff zone.")
		return

	# Pull past the stiffness and half way, then let go: it stays where the hand left it.
	await _drag_on(hall, BOLT, BOLT + Vector2(57, 0))
	var half: float = focus.gesture.progress
	if focus.gesture.stuck or absf(half - 0.5) > 0.06 or state.flags.get("hall_door_latched", false):
		_fail("Half a drag gave progress %.2f or latched the door early." % half)
		return
	await create_timer(0.3).timeout
	if not is_equal_approx(focus.gesture.progress, half):
		_fail("The bolt drifted after the player let go.")
		return
	if hall.door_bolt_world.progress <= 0.05:
		_fail("The room-scale bolt did not follow the hand.")
		return
	if not focus.light_gap.visible or focus.light_gap.size.x <= 0.5 or focus.light_gap.size.x >= 6.0:
		_fail("The light at the door's edge did not narrow with the bolt (width %.1f)." % focus.light_gap.size.x)
		return

	# Leaving now changes nothing; the bolt is loose again on the next visit.
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode != &"roam" or state.flags.get("hall_door_latched", false) or not hall.camera.is_at_rest():
		_fail("Leaving a half-moved bolt changed state or left the camera off its rest framing.")
		return

	# Finish with the mouse. Once free, the bolt is no longer stiff in this visit.
	hall._inspect(hall.archive_door)
	await create_timer(FOCUS_IN).timeout
	await _drag_on(hall, BOLT, BOLT + Vector2(110, 0))
	await create_timer(0.2).timeout
	if not state.flags.get("hall_door_latched", false) or not focus.completed or not hall.door_bolt_world.secured:
		_fail("A full drag did not latch the door in both views.")
		return
	if state.has_note(&"archive-door"):
		_fail("The door alone completed the combined door-and-window check.")
		return
	if focus.light_gap.visible:
		_fail("Light still showed at the edge of a latched door.")
		return
	await create_timer(0.5).timeout
	if hall.ui.caption_text.text != "That should hold. The wind loves finding little gaps." or not hall.ui.caption_panel.visible or hall.mode != &"focus":
		_fail("Kath's line did not follow the latch inside the close shot.")
		return
	# A latched door no longer knocks in the draught.
	var knocks := [0]
	focus.rattled.connect(func(_strength: float) -> void: knocks[0] += 1)
	focus._process(4.0)
	if knocks[0] != 0:
		_fail("The latched door still rattled.")
		return
	if not await _capture("shot-5-latched"):
		return
	hall._unhandled_input(_mouse_button(Vector2(120, 800), true, MOUSE_BUTTON_RIGHT))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode != &"roam":
		_fail("Right-click did not step back from the close shot.")
		return
	hall.kath.position.x = 760.0
	if not await _capture("shot-6-back-in-hall"):
		return
	hall.queue_free()
	await process_frame

	# The keyboard path gives the same result.
	_reset_story()
	hall = await _new_hall()
	focus = hall.focus
	hall._inspect(hall.archive_door)
	await create_timer(FOCUS_IN).timeout
	# Press and release within one frame, so a slow frame cannot turn the tap into a hold.
	hall._unhandled_input(_key(KEY_E))
	hall._unhandled_input(_release(KEY_E))
	await process_frame
	if focus.gesture.progress != 0.0 or state.flags.get("hall_door_latched", false):
		_fail("A tap moved the stiff bolt.")
		return
	await _hold_on(hall, KEY_E, 0.38)
	var partial: float = focus.gesture.progress
	if partial <= 0.2 or partial >= 0.9 or state.flags.get("hall_door_latched", false):
		_fail("A short hold gave progress %.2f." % partial)
		return
	await _hold_on(hall, KEY_E, SLIDE_HOLD)
	if not state.flags.get("hall_door_latched", false) or not focus.completed:
		_fail("Holding E did not carry the bolt home.")
		return
	hall._unhandled_input(_key(KEY_E))
	hall._unhandled_input(_release(KEY_E))
	if state.notes.size() != 0:
		_fail("Pressing E on a latched door wrote a note.")
		return
	hall.queue_free()
	await process_frame
	_pass("stiff start, drag, early release, cancel, mouse and keyboard completion, light gap, rattle, caption")
