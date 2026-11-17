extends "res://tests/support/story_test.gd"
## The hall camera pushes in, the full-screen close shot takes over while it is
## still moving, and the room always comes back to its fixed framing.


func _run() -> void:
	_reset_story()
	var hall: Node2D = await _new_hall()
	var camera: Camera2D = hall.camera
	var focus: CanvasLayer = hall.focus
	var rest_position := camera.position
	if not camera.is_at_rest() or camera.zoom != Vector2.ONE or camera.get_screen_center_position() != Vector2(836, 470.5):
		_fail("At rest the camera does not show the room's original framing.")
		return
	hall.kath.position.x = 120.0
	hall._process(0.0)
	var prompt_before: Vector2 = hall.ui.prompt.position
	if not await _capture("shot-0-hall"):
		return

	# Push in: the camera leads on the real hall while Kath steps beside the door.
	hall._inspect(hall.archive_door)
	await create_timer(0.12).timeout
	if camera.is_at_rest() or focus.picture.modulate.a > 0.05 or hall.kath.controls_enabled or not hall.kath.reaching:
		_fail("The camera did not lead the close shot, or Kath was not reaching for the door.")
		return
	await create_timer(0.14).timeout
	if not await _capture("shot-1-pushing-in"):
		return
	await create_timer(FOCUS_IN).timeout
	if camera.zoom.x < 2.0 or focus.transitioning or not focus.shot:
		_fail("The push-in did not end in a close shot.")
		return
	# No frame, no dimming, no captions: only the door, Kath and a faint Esc.
	if focus.frame.visible or focus.shade.modulate.a > 0.01 or focus.vignette.modulate.a > 0.01 \
		or focus.detail_label.visible or focus.controls_label.visible or focus.title_label.visible:
		_fail("The close shot still looks like a framed pop-up.")
		return
	if focus.picture.size != Vector2(1672, 941) or focus.picture.modulate.a < 0.99:
		_fail("The close shot does not fill the screen.")
		return
	await create_timer(0.35).timeout
	if not focus.figure.visible or focus.figure.modulate.a < 0.9 or absf(hall.kath.position.x - 215.0) > 1.0:
		_fail("Kath was not brought into the close shot.")
		return
	if focus.tip_label.modulate.a < 0.5 or focus.tip_label.text.find("DRAG") == -1:
		_fail("The first hands-on part did not show its one-time tip.")
		return
	if not await _capture("shot-2-over-the-shoulder"):
		return
	var figure_x: float = focus.figure.position.x
	await _hold_on(hall, KEY_E, 0.42)
	if focus.figure.position.x <= figure_x + 5.0:
		_fail("Kath's hand did not travel with the bolt.")
		return
	if not await _capture("shot-3-bolt-half-way"):
		return

	# Esc in the middle of everything returns control quickly and exactly.
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.6).timeout
	if hall.mode != &"roam" or not hall.kath.controls_enabled or hall.kath.reaching or focus.figure.visible:
		_fail("Esc did not hand control back within 0.6 seconds.")
		return
	if camera.position != rest_position or camera.zoom != Vector2.ONE:
		_fail("The camera did not return to its exact rest framing.")
		return
	if absf(hall.kath.position.x - 120.0) > 0.5 or hall.nearest_hotspot(hall.kath.position.x) != hall.archive_door:
		_fail("Kath did not step back to where she stood.")
		return
	hall._process(0.0)
	if hall.ui.prompt.position != prompt_before:
		_fail("The E prompt moved after a close shot.")
		return

	# The tip is for the first time only.
	hall._inspect(hall.archive_door)
	await create_timer(FOCUS_IN + 0.35).timeout
	if focus.tip_label.modulate.a > 0.01:
		_fail("The hands-on tip showed a second time.")
		return
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.6).timeout

	# Esc while the camera is still on its way in.
	hall._inspect(hall.high_window)
	await create_timer(0.1).timeout
	hall._unhandled_input(_key(KEY_ESCAPE))
	await create_timer(0.6).timeout
	if hall.mode != &"roam" or not camera.is_at_rest() or state.flags.get("hall_window_fixed", false):
		_fail("Leaving during the push-in left the camera or the window in a wrong state.")
		return

	# The nameplate is part of the shot: click it, or press Right, to look closer.
	hall._inspect(hall.archive_door)
	await create_timer(FOCUS_IN).timeout
	hall._unhandled_input(_mouse_button(Vector2(1340, 600), true))
	await create_timer(FOCUS_IN).timeout
	if hall.focus_part != 1 or focus.shot or camera.is_at_rest() or hall.mode != &"focus":
		_fail("Clicking the nameplate in the shot did not open it.")
		return
	hall._unhandled_input(_key(KEY_LEFT))
	await create_timer(FOCUS_IN).timeout
	if hall.focus_part != 0 or not focus.shot or focus.shade.modulate.a > 0.01:
		_fail("Returning from the nameplate did not restore the close shot.")
		return
	hall._unhandled_input(_mouse_button(Vector2(800, 400), true, MOUSE_BUTTON_RIGHT))
	await create_timer(FOCUS_OUT).timeout
	if hall.mode != &"roam" or not camera.is_at_rest():
		_fail("Right-click did not step back out of the close shot.")
		return
	hall.queue_free()
	await process_frame
	_pass("rest framing, lead-in, full-screen shot, Kath in frame, tip once, mid-move Esc, exact return, nameplate link")
