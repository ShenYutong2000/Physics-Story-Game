extends "res://tests/support/story_test.gd"
## Step 9: weather chronology, concrete patrol hints, archived notes, and v2 checkpoints.

const HALL_PATH := "res://scenes/library_hall.tscn"
const MACHINE_PATH := "res://scenes/machine_room.tscn"
const SAVE_PATH := "res://tests/_hall_weather_checkpoint.json"
const StoryGuide = preload("res://scripts/story_guide.gd")


func _run() -> void:
	state.persistence_enabled = false
	state.save_path_override = SAVE_PATH
	_cleanup_save()
	var old_file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	old_file.store_string('{"version":1,"scene":"res://scenes/library_hall.tscn"}')
	old_file.close()
	if state.has_checkpoint():
		_fail("An earlier save version still enables Continue.")
		return
	var title: Node2D = load("res://scenes/title_screen.tscn").instantiate()
	root.add_child(title)
	await process_frame
	if title.has_save or title.continue_game.modulate == Color.WHITE:
		_fail("The title screen still presents Continue for an old checkpoint.")
		return
	title.queue_free()
	await process_frame
	_cleanup_save()
	state.notes.clear()
	state.flags.clear()
	state.pending_spawn_tag = &""
	var hall: Node2D = await _open_hall()
	if state.weather_phase() != &"prestorm" or not hall.far.texture.resource_path.contains("archive-prestorm") or hall.rain_streaks.visible:
		_fail("A new hall starts with visible rain.")
		return
	if not await _capture("weather-hall-prestorm"):
		return
	var objective: Dictionary = StoryGuide.current(state)
	if not StoryGuide.hint_text(state, objective, 3, HALL_PATH, 120.0).contains("slide its bolt"):
		_fail("The patrol hint does not name the door operation.")
		return
	state.flags["hall_door_latched"] = true
	if not StoryGuide.hint_text(state, objective, 3, HALL_PATH, 476.0).contains("loose catch"):
		_fail("The patrol hint did not switch to the unfinished window.")
		return
	state.flags["hall_window_fixed"] = true
	state.add_note_once(&"archive-door", "Doors and windows", "Both fastened")
	if not StoryGuide.hint_text(state, objective, 3, HALL_PATH, 967.0).contains("hold E"):
		_fail("The clock hint omitted its hold action.")
		return
	state.flags["hall_clock_wound"] = true
	state.add_note_once(&"clock-housing", "Hall clock", "Wound")
	if not StoryGuide.hint_text(state, objective, 3, HALL_PATH, 1370.0).contains("east service key"):
		_fail("The key hint omitted the exact key.")
		return
	state.flags["hall_east_key_sorted"] = true
	state.add_note_once(&"duty-keys", "Duty keys", "Sorted")
	objective = StoryGuide.current(state)
	if not StoryGuide.hint_text(state, objective, 3, HALL_PATH, 1212.0).contains("ROUND FILED"):
		_fail("The filed-round hint omitted the stamp.")
		return
	state.flags["hall_round_filed"] = true
	state.add_note_once(&"evening-round-filed", "Evening round filed", "Stamped")
	if not state.hall_checks_complete():
		_fail("The completed round did not open the machine room.")
		return
	state.persistence_enabled = true
	hall._on_exit_requested(MACHINE_PATH, "from-hall")
	await process_frame
	var room: Node2D = current_scene
	if room.name != "MachineRoom" or state.weather_phase() != &"rain" or room.rain_streaks.strength < 0.2:
		_fail("Rain did not start when Kath entered the machine room.")
		return
	room._on_exit_requested(HALL_PATH, "from-machine-room")
	await process_frame
	hall = current_scene
	if state.weather_phase() != &"rain" or state.flags.get("hall_rain_heavy", false) or state.flags.get("hall_return_cue_seen", false) or hall.rain_streaks.strength >= 0.5:
		_fail("An early return incorrectly triggered the roof-drip cue or heavy rain.")
		return
	hall._close_dialogue(false)
	hall.kath.position.x = 760.0
	if not await _capture("weather-hall-early-return"):
		return
	hall._on_exit_requested(MACHINE_PATH, "from-hall")
	await process_frame
	room = current_scene
	state.flags["machine_baseline_recorded"] = true
	state.add_note_once(&"machine-reading", "Machine reading", "Still below red")
	room._on_exit_requested(HALL_PATH, "from-machine-room")
	await process_frame
	hall = current_scene
	if state.weather_phase() != &"heavy" or not state.flags.get("hall_return_cue_seen", false) or hall.rain_streaks.strength < 0.99:
		_fail("The recorded reading did not lead to the heavier storm and roof-drip cue.")
		return
	hall._close_dialogue(false)
	hall.kath.position.x = 760.0
	if not await _capture("weather-hall-heavy-return"):
		return
	hall._set_mode(&"journal")
	hall._show_journal()
	if not hall.ui.journal_progress.text.contains("CURRENT TASK PAGE  Blank") or not hall.ui.journal_progress.text.contains("ARCHIVE  Checked round") or not hall.ui.journal_progress.text.contains("WEATHER  Heavy rain"):
		_fail("The journal lost the filed page or weather sequence.")
		return
	hall._close_overlay()
	var note_count: int = state.notes.size()
	if not state.save_checkpoint(HALL_PATH):
		_fail("The new hall checkpoint could not be saved.")
		return
	state.flags.clear()
	state.notes.clear()
	state.persistence_enabled = false
	if not state.resume_checkpoint():
		_fail("The version 2 checkpoint could not be resumed.")
		return
	await process_frame
	hall = current_scene
	if state.weather_phase() != &"heavy" or not hall.round_book_world.filed or state.notes.size() != note_count or hall.mode == &"dialogue":
		_fail("Reloading lost the weather, filed book, or one-shot cue state.")
		return
	state.flags["dawn_reached"] = true
	if state.weather_phase() != &"dawn":
		_fail("Dawn did not supersede the rain phase.")
		return
	hall.queue_free()
	await process_frame
	hall = await _open_hall()
	if not hall.far.texture.resource_path.contains("archive-dawn") or hall.rain_streaks.visible:
		_fail("The revisited hall returned to rainy night after dawn.")
		return
	if not await _capture("weather-hall-dawn"):
		return
	for scene_path in [MACHINE_PATH, "res://scenes/upper_stacks.tscn", "res://scenes/kath_room.tscn"]:
		hall.queue_free()
		await process_frame
		hall = load(scene_path).instantiate()
		root.add_child(hall)
		current_scene = hall
		await process_frame
		if not hall.far.texture.resource_path.contains("archive-dawn") or hall.rain_streaks.visible:
			_fail("Dawn did not carry into " + scene_path)
			return
	state.persistence_enabled = false
	_cleanup_save()
	state.save_path_override = ""
	print("HALL_WEATHER_SAVE_OK: prestorm, rain, early return, heavy rain, dawn, hints, journal, v1 rejection, v2 resume")
	quit(0)


func _open_hall() -> Node2D:
	var hall: Node2D = load(HALL_PATH).instantiate()
	root.add_child(hall)
	current_scene = hall
	await process_frame
	if hall.mode == &"dialogue":
		hall._close_dialogue(false)
	return hall


func _cleanup_save() -> void:
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH + suffix))
