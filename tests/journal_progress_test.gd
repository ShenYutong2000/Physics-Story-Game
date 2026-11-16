extends "res://tests/support/story_test.gd"
## Every room's notes panel reflects the whole journey, not just its own chapter.
## (Prologue rooms used to pass partial progress and showed the road as unreached.)

const MACHINE: PackedScene = preload("res://scenes/machine_room.tscn")
const OBSERVATORY: PackedScene = preload("res://scenes/chapter1_observatory.tscn")


func _run() -> void:
	_reset_story()
	state.flags["machine_baseline_recorded"] = true
	state.flags["service_gate_open"] = true
	state.flags["service_road_end_reached"] = true
	for scene in [MACHINE, OBSERVATORY]:
		var room: Node2D = await _open_scene(scene)
		room._close_overlay()
		await _tap(KEY_J)
		if room.mode != &"journal":
			_fail("%s did not open the notes panel with J." % room.name)
			return
		var progress: String = room.ui.journal_progress.text
		if not progress.contains("SERVICE ROAD  Castle entrance reached"):
			_fail("%s showed stale service-road progress:\n%s" % [room.name, progress])
			return
		if not progress.contains("MACHINE ROOM  1 / 1"):
			_fail("%s lost the machine-room reading." % room.name)
			return
		await _tap(KEY_J)
		if room.mode != &"roam":
			_fail("%s did not close the notes panel with J." % room.name)
			return
		room.queue_free()
		await process_frame
	_pass("notes show the same journey progress from prologue and Chapter I rooms")
