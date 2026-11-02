extends Node2D
## The restored wing's records reveal the Grand Archive link and the next station.

const ENGINE_ROOM_SCENE := "res://scenes/chapter1_engine_room.tscn"
const CLICK_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const DOCUMENTS := [
	{
		"id": &"observatory-work-record",
		"title": "WORK RECORD",
		"body": "Grand Archive — Castle Observation Station\n\nTrial 18: basket service; direction dial.\n\nEarlier estimate crossed out. Keep the measured result.\n\nSigned: Kath · Erin",
		"note_title": "A signed castle record",
		"note_body": "A Castle Observation Station work record carries Kath's and Erin's signatures. It lists basket maintenance and direction tests under the Grand Archive heading. Its filing marks match the old library records.",
		"reaction": "Those are our signatures. The castle and my library used the same Grand Archive records."
	},
	{
		"id": &"observatory-floating-slip",
		"title": "FLOATING ISLES",
		"body": "Floating Isles — Buoyancy Station\n\nAwaiting comparison results for airship chambers and floating platforms.\n\nCastle instrument trial pending.\n\nLast exchange: before the Night of Unnaming.",
		"note_title": "An unfinished comparison",
		"note_body": "The Floating Isles Buoyancy Station was waiting for Castle Observation Station results about airship buoyancy chambers and floating platforms. The last exchange predates the Night of Unnaming; the comparison was never completed here.",
		"reaction": "The Floating Isles were waiting for our results. Their copy might show what this folder cannot."
	},
	{
		"id": &"observatory-withdrawn",
		"title": "WITHDRAWN",
		"body": "Reason for withdrawal:\n\n________________________\n\nNo explanation accompanies this page. The measurements remain in the folder.",
		"note_title": "A withdrawal without a reason",
		"note_body": "A castle processing page is stamped WITHDRAWN, but its reason field is blank. The library held the same kind of unexplained withdrawal. Neither page identifies who made the decision or why.",
		"reaction": "The reason is blank, just like the page at the library. I still don't know who withdrew these records."
	}
]

@onready var state: Node = get_node("/root/PrologueState")
@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var engine_return: Node2D = $EngineReturn
@onready var records: Node2D = $Records
@onready var telescope: Node2D = $Telescope
@onready var worktable: Node2D = $Worktable
@onready var drawer: Sprite2D = $ArchiveDrawer
@onready var telescope_pivot: Node2D = $TelescopePivot
@onready var document_modal: Node2D = $DocumentModal
@onready var document_title: Label = $DocumentModal/DocumentTitle
@onready var document_body: Label = $DocumentModal/DocumentBody
@onready var document_footer: Label = $DocumentModal/DocumentFooter
@onready var hotspots: Array[Node] = [engine_return, records, telescope, worktable]

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var document_index := 0
var sound_player: AudioStreamPlayer


func _ready() -> void:
	state.take_spawn_tag()
	kath.position = Vector2(1465, 820)
	kath.floor_y = 820.0
	kath.left_limit = 155.0
	kath.right_limit = 1530.0
	drawer.visible = state.flags.get("observatory_drawer_open", false)
	telescope_pivot.rotation_degrees = -6.0 if state.flags.get("observatory_scope_angled", false) else 0.0
	document_modal.visible = false
	sound_player = AudioStreamPlayer.new()
	sound_player.stream = CLICK_SOUND
	sound_player.volume_db = -15.0
	add_child(sound_player)
	if not _archive_accessible():
		_start_dialogue(["The wing is not secured at home. I should return to the fixed engine room before inspecting these records."])
	elif not state.flags.get("observatory_arrival_seen", false):
		state.flags["observatory_arrival_seen"] = true
		_start_dialogue(["The passage lines up again. An archive drawer was shaken open during the turn.", "Erin is checking the engine. I can read the surviving records here."])
	elif state.flags.get("observatory_page_stitched", false):
		ui.show_hint("Take the repaired notebook back to Erin in the engine room.", 5.0)
	elif state.flags.get("observatory_archive_complete", false):
		ui.show_hint("The three records are noted. Use the worktable to repair the notebook.", 5.0)


func _archive_accessible() -> bool:
	return state.castle_pose == &"restored" and state.flags.get("engine_restored", false)


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var action := "RETURN" if closest == engine_return else "INSPECT"
	if closest == records:
		action = "READ" if drawer.visible else "OPEN"
	elif closest == worktable and state.flags.get("observatory_archive_complete", false) and not state.flags.get("observatory_page_stitched", false):
		action = "STITCH"
	ui.show_prompt(closest.display_name, closest.approach_x, action, 315.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		else:
			_close_overlay()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			var closest: Node = nearest_hotspot(kath.position.x)
			if closest != null:
				_inspect(closest)
		elif event.is_action_pressed("toggle_journal"):
			get_viewport().set_input_as_handled()
			_set_mode(&"journal")
			_show_journal()
	elif mode == &"records":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			get_viewport().set_input_as_handled()
			document_index = posmod(document_index + (-1 if event.is_action_pressed("move_left") else 1), DOCUMENTS.size())
			_show_document(document_index)
		elif event.is_action_pressed("advance_dialogue") or event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_record_document()
	elif mode == &"stitch" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_stitch_page()
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		dialogue_index += 1
		if dialogue_index >= dialogue_lines.size():
			_close_overlay()
		else:
			ui.show_dialogue(dialogue_lines[dialogue_index], kath.global_position)
	elif mode == &"journal":
		if event.is_action_pressed("toggle_journal"):
			get_viewport().set_input_as_handled()
			_close_overlay()
		elif event.is_action_pressed("advance_dialogue") and state.has_note(&"newton-note"):
			get_viewport().set_input_as_handled()
			_set_mode(&"paper")
			ui.show_torn_page(true)
		elif event.is_action_pressed("move_up") or event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			ui.scroll_journal(-1 if event.is_action_pressed("move_up") else 1)
	elif mode == &"paper" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_set_mode(&"journal")
		_show_journal()
	elif mode == &"paused" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_close_overlay()


func nearest_hotspot(feet_x: float) -> Node:
	var best: Node = null
	var best_distance := INF
	for hotspot in hotspots:
		if hotspot != engine_return and not _archive_accessible():
			continue
		if hotspot.is_reachable(feet_x) and hotspot.distance_from(feet_x) < best_distance:
			best = hotspot
			best_distance = hotspot.distance_from(feet_x)
	return best


func _inspect(hotspot: Node) -> void:
	if hotspot == engine_return:
		_set_mode(&"travel")
		ui.hide_modals()
		state.travel_to(ENGINE_ROOM_SCENE, &"from-observatory")
	elif not _archive_accessible():
		_start_dialogue(["The wing must be secured before I search the records."])
	elif hotspot == records:
		if not drawer.visible:
			_open_drawer()
		else:
			_open_records()
	elif hotspot == telescope:
		state.flags["observatory_scope_angled"] = not state.flags.get("observatory_scope_angled", false)
		telescope_pivot.rotation_degrees = -6.0 if state.flags["observatory_scope_angled"] else 0.0
		wick.react_to(810.0, 350.0)
		state.add_note_once(&"observatory-steady-scope", "A steady view", "The telescope points across the coast. With the wing's normal lock engaged, the fixed tower stays at the same position in its view.")
		_start_dialogue(["The telescope holds a steady view of the fixed tower. Farther out, I can see the coast beyond it."])
	elif hotspot == worktable:
		if not state.flags.get("observatory_archive_complete", false):
			_start_dialogue(["My notebook is here. First I should read the three pages in the shaken drawer."])
		elif state.flags.get("observatory_page_stitched", false):
			_start_dialogue(["The torn page is secured beside my new observations. Erin is still at the engine; I should tell her what the records showed."])
		else:
			_set_mode(&"stitch")
			ui.show_chapter1_notebook()


func _open_drawer() -> void:
	state.flags["observatory_drawer_open"] = true
	drawer.visible = true
	sound_player.play()
	wick.react_to(330.0, 495.0)
	_start_dialogue(["The drawer's catch has sprung. Inside are a signed work record, an unfinished station slip, and a withdrawn page."])


func _open_records() -> void:
	_set_mode(&"records")
	ui.hide_modals()
	document_index = 0
	_show_document(document_index)
	ui.hide_prompt()


func _show_document(index: int) -> void:
	document_index = index
	var document: Dictionary = DOCUMENTS[index]
	document_title.text = document["title"] + ("  ✓" if state.has_note(document["id"]) else "")
	document_title.add_theme_color_override("font_color", Color("9b4e49") if index == 2 else Color(0.18, 0.14, 0.11, 1.0))
	document_body.text = document["body"]
	document_footer.text = "%d/3  ←/→ PAGE  %s  ESC" % [index + 1, "ENTER CLOSE" if state.has_note(document["id"]) else "ENTER NOTE"]
	document_modal.visible = true


func _record_document() -> void:
	var document: Dictionary = DOCUMENTS[document_index]
	var already_recorded: bool = state.has_note(document["id"])
	if not already_recorded:
		state.add_note_once(document["id"], document["note_title"], document["note_body"])
		sound_player.play()
	_close_overlay()
	if already_recorded:
		return
	if _archive_documents_recorded():
		_complete_archive_inference()
	else:
		_start_dialogue([document["reaction"]])


func _archive_documents_recorded() -> bool:
	for document in DOCUMENTS:
		if not state.has_note(document["id"]):
			return false
	return true


func _complete_archive_inference() -> void:
	if state.flags.get("observatory_archive_complete", false):
		return
	state.flags["observatory_archive_complete"] = true
	state.add_note_once(&"observatory-grand-archive-link", "A connected archive", "Kath and Erin signed work at the Grand Archive's Castle Observation Station. Its filing system matches Kath's library. The Floating Isles station awaited a comparison, while a WITHDRAWN page gives no reason for its removal. The stations were linked; the withdrawal remains unexplained.")
	_start_dialogue(["Our names, the same filing marks, and the station heading connect this castle to my library's archive.", "The Floating Isles were waiting for a comparison. The withdrawal still has no reason. I'll stitch this page into my notebook before I tell Erin."])


func _stitch_page() -> void:
	if not state.flags.get("observatory_archive_complete", false):
		return
	state.flags["observatory_page_stitched"] = true
	state.add_note_once(&"observatory-page-stitched", "The missing leaf returned", "I stitched the F = ma fragment back beside this visit's rope, load, stopping-distance and castle-stop observations. The old formula is still not a complete explanation to me; the new measurements and questions stay with it.")
	sound_player.play()
	wick.react_to(1240.0, 420.0)
	_close_overlay()
	_start_dialogue(["The torn edge fits. I stitch the old page back in, beside the rope and brake notes I made today.", "The formula still asks a question I cannot answer completely. These new observations are mine to keep. I should tell Erin what the archive revealed."])


func _start_dialogue(lines: Array[String]) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	_set_mode(&"dialogue")
	ui.show_dialogue(lines[0], kath.global_position)


func _show_journal() -> void:
	ui.show_journal(state.notes, state.hall_checks_complete(), bool(state.flags.get("machine_baseline_recorded", false)), bool(state.flags.get("stacks_bucket_moved", false)), bool(state.flags.get("stacks_page_collected", false)), bool(state.flags.get("room_notebook_compared", false)), bool(state.flags.get("incident_complete", false)), state.room_preparation_complete(), bool(state.flags.get("machine_incident_active", false)), bool(state.flags.get("service_gate_open", false)), bool(state.flags.get("service_road_end_reached", false)))


func _close_overlay() -> void:
	document_modal.visible = false
	ui.hide_modals()
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"
