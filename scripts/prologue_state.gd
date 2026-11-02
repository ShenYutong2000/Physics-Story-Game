extends Node
## Story state, single-slot checkpoints, and first-play timing.

const HALL_NOTE_IDS := [&"archive-door", &"clock-housing", &"maintenance-sheet"]
const UPPER_STACKS_NOTE_IDS := [&"leak-observation", &"newton-note"]
const ROOM_NOTE_IDS := [&"notebook-match", &"castle-alarm"]
const CASTLE_POSE_ORDER := [&"upright", &"tilted", &"inverted", &"restored"]
const CASTLE_POSE_ANGLES_DEGREES := {
	&"upright": 0.0,
	&"tilted": 12.0,
	&"inverted": 180.0,
	&"restored": 0.0,
}
const SAVE_VERSION := 1
const SAVE_PATH := "user://footnotes-chapter1-save.json"
const STORY_SCENES := [
	"res://scenes/library_hall.tscn",
	"res://scenes/machine_room.tscn",
	"res://scenes/upper_stacks.tscn",
	"res://scenes/kath_room.tscn",
	"res://scenes/service_road.tscn",
	"res://scenes/castle_control_walkway.tscn",
	"res://scenes/chapter1_inverted_room.tscn",
	"res://scenes/chapter1_maintenance_shaft.tscn",
	"res://scenes/chapter1_engine_room.tscn",
	"res://scenes/chapter1_observatory.tscn",
]

var notes: Array[Dictionary] = []
var flags: Dictionary = {}
var pending_spawn_tag: StringName = &""
var castle_pose: StringName = &"upright"
var persistence_enabled := false
var save_path_override := ""
var play_seconds := 0.0
var chapter1_start_seconds := -1.0
var chapter1_finish_seconds := -1.0
var _checkpoint_timer := 0.0
var _last_checkpoint_signature := ""


func _process(delta: float) -> void:
	if not persistence_enabled:
		return
	var scene := get_tree().current_scene
	if scene == null or not STORY_SCENES.has(scene.scene_file_path):
		return
	var mode: StringName = scene.get("mode")
	if mode != &"paused":
		play_seconds += delta
	if chapter1_start_seconds < 0.0 and scene.scene_file_path == "res://scenes/castle_control_walkway.tscn":
		chapter1_start_seconds = play_seconds
	if chapter1_finish_seconds < 0.0 and flags.get("chapter1_complete", false):
		chapter1_finish_seconds = play_seconds
		var elapsed := roundi(chapter1_elapsed_seconds())
		print("CHAPTER_I_PLAYTIME: %02d:%02d (excludes pauses)" % [floori(elapsed / 60.0), elapsed % 60])
		save_checkpoint(scene.scene_file_path)
	if mode not in [&"roam", &"paused", &"chapter_end"]:
		return
	_checkpoint_timer += delta
	if _checkpoint_timer >= 5.0:
		_checkpoint_timer = 0.0
		save_checkpoint(scene.scene_file_path)


func _input(event: InputEvent) -> void:
	if not persistence_enabled or not event is InputEventKey or not event.pressed or event.echo or event.keycode != KEY_Q:
		return
	var scene := get_tree().current_scene
	if scene == null or not STORY_SCENES.has(scene.scene_file_path) or scene.get("mode") != &"paused":
		return
	get_viewport().set_input_as_handled()
	save_checkpoint(scene.scene_file_path)
	get_tree().quit()


func start_new_game() -> void:
	notes.clear()
	flags.clear()
	pending_spawn_tag = &""
	castle_pose = &"upright"
	play_seconds = 0.0
	chapter1_start_seconds = -1.0
	chapter1_finish_seconds = -1.0
	_checkpoint_timer = 0.0
	_last_checkpoint_signature = ""
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_path()))
	persistence_enabled = true
	travel_to(STORY_SCENES[0], &"")


func has_checkpoint() -> bool:
	return not _read_checkpoint().is_empty()


func resume_checkpoint() -> bool:
	var saved := _read_checkpoint()
	if saved.is_empty():
		return false
	var restored_notes: Array[Dictionary] = []
	for entry in saved["notes"]:
		restored_notes.append({"id": StringName(entry["id"]), "title": entry["title"], "body": entry["body"]})
	notes = restored_notes
	flags = saved["flags"].duplicate(true)
	if flags.has("shaft_rescue_phase"):
		flags["shaft_rescue_phase"] = StringName(flags["shaft_rescue_phase"])
	castle_pose = StringName(saved["castle_pose"])
	play_seconds = float(saved["play_seconds"])
	chapter1_start_seconds = float(saved["chapter1_start_seconds"])
	chapter1_finish_seconds = float(saved["chapter1_finish_seconds"])
	pending_spawn_tag = StringName(saved["spawn_tag"])
	_checkpoint_timer = 0.0
	_last_checkpoint_signature = ""
	persistence_enabled = true
	var error := get_tree().change_scene_to_file(saved["scene"])
	if error != OK:
		persistence_enabled = false
		pending_spawn_tag = &""
		push_error("Unable to resume scene '%s' (error %d)." % [saved["scene"], error])
		return false
	return true


func chapter1_elapsed_seconds() -> float:
	if chapter1_start_seconds < 0.0:
		return 0.0
	return maxf(0.0, (chapter1_finish_seconds if chapter1_finish_seconds >= 0.0 else play_seconds) - chapter1_start_seconds)


func save_checkpoint(scene_path: String, spawn_tag: StringName = &"") -> bool:
	if not persistence_enabled or not STORY_SCENES.has(scene_path):
		return false
	var serialized_notes: Array[Dictionary] = []
	for entry in notes:
		serialized_notes.append({"id": String(entry["id"]), "title": entry["title"], "body": entry["body"]})
	var serialized_flags := flags.duplicate(true)
	for key in serialized_flags:
		if serialized_flags[key] is StringName:
			serialized_flags[key] = String(serialized_flags[key])
	var snapshot := {
		"version": SAVE_VERSION,
		"scene": scene_path,
		"spawn_tag": String(spawn_tag),
		"castle_pose": String(castle_pose),
		"flags": serialized_flags,
		"notes": serialized_notes,
		"play_seconds": play_seconds,
		"chapter1_start_seconds": chapter1_start_seconds,
		"chapter1_finish_seconds": chapter1_finish_seconds,
	}
	var encoded := JSON.stringify(snapshot)
	if encoded == _last_checkpoint_signature:
		return true
	var file := FileAccess.open(_save_path(), FileAccess.WRITE)
	if file == null:
		push_error("Could not write story checkpoint (error %d)." % FileAccess.get_open_error())
		return false
	file.store_string(encoded)
	file.flush()
	file.close()
	_last_checkpoint_signature = encoded
	return true


func _read_checkpoint() -> Dictionary:
	if not FileAccess.file_exists(_save_path()):
		return {}
	var file := FileAccess.open(_save_path(), FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or parsed.get("version") != SAVE_VERSION:
		return {}
	if not parsed.get("scene") is String or not STORY_SCENES.has(parsed["scene"]) or not ResourceLoader.exists(parsed["scene"]):
		return {}
	if not parsed.get("spawn_tag") is String or not parsed.get("castle_pose") is String or not CASTLE_POSE_ORDER.has(StringName(parsed["castle_pose"])):
		return {}
	if not parsed.get("flags") is Dictionary or not parsed.get("notes") is Array:
		return {}
	for entry in parsed["notes"]:
		if not entry is Dictionary or not entry.get("id") is String or not entry.get("title") is String or not entry.get("body") is String:
			return {}
	for field in ["play_seconds", "chapter1_start_seconds", "chapter1_finish_seconds"]:
		if not parsed.get(field) is float and not parsed.get(field) is int:
			return {}
	return parsed


func _save_path() -> String:
	return SAVE_PATH if save_path_override.is_empty() else save_path_override


func transition_castle_pose(next_pose: StringName) -> bool:
	var current_index := CASTLE_POSE_ORDER.find(castle_pose)
	var next_index := CASTLE_POSE_ORDER.find(next_pose)
	if next_index < 0:
		push_error("Unknown castle pose '%s'." % next_pose)
		return false
	if next_pose == castle_pose:
		return true
	if current_index < 0 or next_index != current_index + 1:
		push_error("Invalid castle pose transition: '%s' to '%s'." % [castle_pose, next_pose])
		return false
	castle_pose = next_pose
	return true


func castle_pose_angle_radians(pose: StringName = &"") -> float:
	var resolved_pose := castle_pose if pose == &"" else pose
	if not CASTLE_POSE_ANGLES_DEGREES.has(resolved_pose):
		push_error("Unknown castle pose angle '%s'." % resolved_pose)
		return 0.0
	return deg_to_rad(float(CASTLE_POSE_ANGLES_DEGREES[resolved_pose]))


func add_note_once(note_id: StringName, title: String, body: String) -> bool:
	for note in notes:
		if note["id"] == note_id:
			return false
	notes.append({"id": note_id, "title": title, "body": body})
	return true


func has_note(note_id: StringName) -> bool:
	for note in notes:
		if note["id"] == note_id:
			return true
	return false


func hall_checks_complete() -> bool:
	for note_id in HALL_NOTE_IDS:
		if not has_note(note_id):
			return false
	return true


func upper_stacks_unlocked() -> bool:
	return bool(flags.get("machine_baseline_recorded", false))


func upper_stacks_complete() -> bool:
	for note_id in UPPER_STACKS_NOTE_IDS:
		if not has_note(note_id):
			return false
	return true


func room_preparation_complete() -> bool:
	return bool(flags.get("room_notebook_compared", false)) \
		and bool(flags.get("room_rested", false)) \
		and bool(flags.get("room_bag_packed", false))


func machine_incident_complete() -> bool:
	return bool(flags.get("incident_valve_two_open", false)) \
		and bool(flags.get("incident_valve_four_open", false)) \
		and bool(flags.get("incident_drive_stopped", false)) \
		and bool(flags.get("incident_tilt_observed", false))


func travel_to(scene_path: String, spawn_tag: StringName) -> void:
	pending_spawn_tag = spawn_tag
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		pending_spawn_tag = &""
		push_error("Unable to open scene '%s' (error %d)." % [scene_path, error])
	else:
		if scene_path == "res://scenes/castle_control_walkway.tscn" and chapter1_start_seconds < 0.0:
			chapter1_start_seconds = play_seconds
		save_checkpoint(scene_path, spawn_tag)


func take_spawn_tag() -> StringName:
	var result := pending_spawn_tag
	pending_spawn_tag = &""
	return result
