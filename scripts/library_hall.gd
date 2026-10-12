extends Node2D
## Week 2's complete, single-room evening patrol.

const INSPECTIONS := {
	"archive-door": {"title": "Archive door", "body": "Its old handle sequence still works."},
	"clock-housing": {"title": "Old clock", "body": "Wick heard a rattle, though the clock still runs."},
	"maintenance-sheet": {"title": "Maintenance sheet", "body": "Five checks are listed, with no reasons given."}
}

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var hotspots: Array[Node] = [$ArchiveDoor, $OldClock, $MaintenanceSheet]

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var pending_inspection: StringName = &""
var notes: Array[Dictionary] = []
var seen: Dictionary = {}
var completion_played := false
var first_note_hint_pending := false


func _ready() -> void:
	_start_dialogue(["Evening rounds. The door, the clock, the checklist... then the upper shelves."])


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
	else:
		ui.show_prompt(closest.display_name, closest.approach_x)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"dialogue":
			_close_dialogue(false)
		else:
			_close_modal()
		get_viewport().set_input_as_handled()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			var closest: Node = nearest_hotspot(kath.position.x)
			if closest != null:
				_inspect(closest)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_journal"):
			_set_mode(&"journal")
			ui.show_journal(notes)
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
	pending_inspection = hotspot.interaction_id
	match hotspot.content_key:
		&"door":
			_start_dialogue(["The archive door catches on the third turn.", "I remember the handle sequence. I wish I remembered why it works."])
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
		_maybe_finish()
	_show_pending_note_hint()


func _close_sheet() -> void:
	# Closing the paper completes this inspection; Kath then reacts to Wick.
	var inspected_id := pending_inspection
	pending_inspection = &""
	_record(inspected_id, false)
	_start_dialogue(["Wick, you noticed the last line too. Upper shelves... that's still on tonight's route."])


func _close_modal() -> void:
	if mode == &"inspection":
		_close_sheet()
		return
	if mode == &"dialogue":
		pending_inspection = &""
	ui.hide_modals()
	_set_mode(&"roam")


func _record(inspection_id: StringName, show_completion: bool = true) -> void:
	if inspection_id == &"":
		return
	if not seen.has(inspection_id):
		seen[inspection_id] = true
		var item: Dictionary = INSPECTIONS[String(inspection_id)]
		notes.append({"id": inspection_id, "title": item["title"], "body": item["body"]})
		if notes.size() == 1:
			first_note_hint_pending = true
	if show_completion:
		_maybe_finish()
	_show_pending_note_hint()


func _maybe_finish() -> void:
	if notes.size() == 3 and not completion_played:
		completion_played = true
		_start_dialogue(["All three checks are done. The upper shelves are next."])


func _show_pending_note_hint() -> void:
	if first_note_hint_pending and mode == &"roam":
		first_note_hint_pending = false
		ui.show_hint("J  NOTES")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"
