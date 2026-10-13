extends Node2D
## The Hall patrol and its connection to the Machine Room.

const DRIP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/water-drop.wav")
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-library.wav")

const INSPECTIONS := {
	"archive-door": {"title": "Archive door", "body": "Its old handle sequence still works."},
	"clock-housing": {"title": "Old clock", "body": "Wick heard a rattle, though the clock still runs."},
	"maintenance-sheet": {"title": "Maintenance sheet", "body": "Five checks are listed, with no reasons given."}
}

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var archive_door: Node2D = $ArchiveDoor
@onready var upper_stacks_entry: Node2D = $UpperStacksEntry
@onready var hotspots: Array[Node] = [$ArchiveDoor, $OldClock, $MaintenanceSheet, $UpperStacksEntry]
@onready var state: Node = get_node("/root/PrologueState")
@onready var notes: Array[Dictionary] = state.notes

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var pending_inspection: StringName = &""
var first_note_hint_pending := false
var one_shot_audio: AudioStreamPlayer
var completion_played := false


func _ready() -> void:
	completion_played = bool(state.flags.get("hall_complete_line_seen", false))
	archive_door.exit_requested.connect(_on_exit_requested)
	upper_stacks_entry.exit_requested.connect(_on_exit_requested)
	one_shot_audio = AudioStreamPlayer.new()
	one_shot_audio.name = "OneShotAudio"
	add_child(one_shot_audio)
	var ambience := AudioStreamPlayer.new()
	ambience.name = "HallAmbience"
	ambience.stream = AMBIENCE
	ambience.volume_db = -17.0
	add_child(ambience)
	ambience.play()
	var spawn_tag: StringName = state.take_spawn_tag()
	if spawn_tag == &"from-machine-room":
		kath.position.x = 120.0
		if state.flags.get("machine_baseline_recorded", false) \
			and not state.flags.get("hall_return_cue_seen", false):
			state.flags["hall_return_cue_seen"] = true
			one_shot_audio.stream = DRIP_SOUND
			one_shot_audio.play()
			_start_dialogue(["The storm has strengthened. A drop just fell from the ceiling above the upper stacks.", "The machine reading is safe for now. I should check where that water is coming from."])
		elif not state.flags.get("early_return_cue_seen", false):
			state.flags["early_return_cue_seen"] = true
			_start_dialogue(["I haven't written down the machine-room reading yet. The service stairs are still open."])
	elif spawn_tag == &"from-upper-stacks":
		kath.position.x = 1530.0
	elif not state.flags.get("hall_intro_seen", false):
		state.flags["hall_intro_seen"] = true
		_start_dialogue(["Evening rounds. The door, the clock, the checklist... then the machine-room reading."])


func _exit_tree() -> void:
	if is_instance_valid(one_shot_audio):
		one_shot_audio.stop()
	var ambience := get_node_or_null("HallAmbience") as AudioStreamPlayer
	if ambience != null:
		ambience.stop()


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	var hall_complete: bool = state.hall_checks_complete()
	archive_door.display_name = "Machine Room" if hall_complete else "Archive door"
	upper_stacks_entry.display_name = "Upper Stacks" if state.upper_stacks_unlocked() else "Upper Stacks (inspect)"
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
	else:
		var can_enter_machine := closest == archive_door and hall_complete
		var can_enter_stacks: bool = closest == upper_stacks_entry and state.upper_stacks_unlocked()
		var action := "ENTER" if can_enter_machine or can_enter_stacks else "INSPECT"
		ui.show_prompt(closest.display_name, closest.approach_x, action)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"dialogue":
			_close_dialogue(false)
		elif mode == &"paper":
			_return_from_saved_page()
		else:
			_close_modal()
		get_viewport().set_input_as_handled()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			# An exit removes this scene immediately, so consume the key first.
			get_viewport().set_input_as_handled()
			var closest: Node = nearest_hotspot(kath.position.x)
			if closest != null:
				_inspect(closest)
		elif event.is_action_pressed("toggle_journal"):
			_set_mode(&"journal")
			_show_journal()
			get_viewport().set_input_as_handled()
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()
	elif mode == &"inspection" and event.is_action_pressed("advance_dialogue"):
		_close_sheet()
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("toggle_journal"):
		_close_modal()
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("advance_dialogue") and state.has_note(&"newton-note"):
		_set_mode(&"paper")
		ui.show_torn_page(true)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("move_up"):
		ui.scroll_journal(-1)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("move_down"):
		ui.scroll_journal(1)
		get_viewport().set_input_as_handled()
	elif mode == &"paper" and (event.is_action_pressed("advance_dialogue") or event.is_action_pressed("toggle_journal")):
		_return_from_saved_page()
		get_viewport().set_input_as_handled()
	elif mode == &"paused":
		if event.is_action_pressed("advance_dialogue"):
			_close_modal()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
			get_tree().quit()


func nearest_hotspot(feet_x: float) -> Node:
	var best: Node = null
	var best_distance := INF
	for hotspot in hotspots:
		if not hotspot.is_reachable(feet_x):
			continue
		var distance: float = hotspot.distance_from(feet_x)
		if distance < best_distance:
			best = hotspot
			best_distance = distance
	return best


func _inspect(hotspot: Node) -> void:
	if hotspot == archive_door and state.hall_checks_complete():
		archive_door.request_exit()
		return
	if hotspot == upper_stacks_entry:
		if state.upper_stacks_unlocked():
			upper_stacks_entry.request_exit()
		else:
			_start_dialogue(["The upper stairs can wait. I should write down the machine-room reading first."])
		return
	pending_inspection = hotspot.interaction_id
	match hotspot.content_key:
		&"door":
			_start_dialogue(["The archive door catches on the third turn.", "The service stairs behind it lead down to the machine room."])
		&"clock":
			wick.react_to(967.0, 490.0)
			_start_dialogue(["Still ticking. I wound it this morning.", "You heard that little rattle too, Wick? I'll note it down."])
		&"sheet":
			wick.react_to(1212.0, 450.0)
			_set_mode(&"inspection")
			ui.show_sheet()
		_:
			pending_inspection = &""


func _start_dialogue(lines: Array[String]) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	_set_mode(&"dialogue")
	ui.show_dialogue(dialogue_lines[0], kath.global_position)


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		ui.show_dialogue(dialogue_lines[dialogue_index], kath.global_position)
	else:
		_close_dialogue(true)


func _close_dialogue(completed: bool) -> void:
	var inspected_id := pending_inspection
	pending_inspection = &""
	_close_modal()
	if completed and inspected_id != &"":
		_record(inspected_id)
	elif completed:
		_maybe_finish_hall()
	_show_pending_note_hint()


func _close_sheet() -> void:
	var inspected_id := pending_inspection
	pending_inspection = &""
	_record(inspected_id, false)
	_start_dialogue(["Wick, you noticed the last line too. I'll record the machine reading before I climb to the upper shelves."])


func _close_modal() -> void:
	if mode == &"inspection":
		_close_sheet()
		return
	if mode == &"dialogue":
		pending_inspection = &""
	ui.hide_modals()
	_set_mode(&"roam")


func _show_journal() -> void:
	ui.show_journal(notes, state.hall_checks_complete(), bool(state.flags.get("machine_baseline_recorded", false)), bool(state.flags.get("stacks_bucket_moved", false)), bool(state.flags.get("stacks_page_collected", false)))


func _return_from_saved_page() -> void:
	_set_mode(&"journal")
	_show_journal()


func _record(inspection_id: StringName, show_completion: bool = true) -> void:
	if inspection_id == &"":
		return
	var item: Dictionary = INSPECTIONS[String(inspection_id)]
	var added: bool = state.add_note_once(inspection_id, item["title"], item["body"])
	if added and notes.filter(func(entry: Dictionary) -> bool: return entry["id"] in state.HALL_NOTE_IDS).size() == 1:
		first_note_hint_pending = true
	if show_completion:
		_maybe_finish_hall()
	_show_pending_note_hint()


func _maybe_finish_hall() -> void:
	if state.hall_checks_complete() and not completion_played:
		completion_played = true
		state.flags["hall_complete_line_seen"] = true
		_start_dialogue(["The hall is checked. I should record the machine-room reading before I investigate the upper shelves."])


func _show_pending_note_hint() -> void:
	if first_note_hint_pending and mode == &"roam":
		first_note_hint_pending = false
		ui.show_hint("J  NOTES")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"


func _on_exit_requested(destination_scene: String, spawn_tag: String) -> void:
	if destination_scene == "res://scenes/machine_room.tscn" and not state.hall_checks_complete():
		return
	if destination_scene == "res://scenes/upper_stacks.tscn" and not state.upper_stacks_unlocked():
		return
	state.travel_to(destination_scene, StringName(spawn_tag))
