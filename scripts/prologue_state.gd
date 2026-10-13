extends Node
## Session-only state shared between the prologue rooms.

const HALL_NOTE_IDS := [&"archive-door", &"clock-housing", &"maintenance-sheet"]
const UPPER_STACKS_NOTE_IDS := [&"leak-observation", &"newton-note"]
const ROOM_NOTE_IDS := [&"notebook-match", &"castle-alarm"]

var notes: Array[Dictionary] = []
var flags: Dictionary = {}
var pending_spawn_tag: StringName = &""


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
		and bool(flags.get("incident_rotation_seen", false))


func travel_to(scene_path: String, spawn_tag: StringName) -> void:
	pending_spawn_tag = spawn_tag
	var error := get_tree().change_scene_to_file(scene_path)
	if error != OK:
		pending_spawn_tag = &""
		push_error("Unable to open scene '%s' (error %d)." % [scene_path, error])


func take_spawn_tag() -> StringName:
	var result := pending_spawn_tag
	pending_spawn_tag = &""
	return result
