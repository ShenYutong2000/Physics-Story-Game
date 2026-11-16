extends StoryRoom
## The restored wing's records reveal the Grand Archive link and the next station.

const ENGINE_ROOM_SCENE := "res://scenes/chapter1_engine_room.tscn"
const CLICK_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const CLICK_DB := -15.0
const WITHDRAWN_INK := Color(155 / 255.0, 78 / 255.0, 73 / 255.0)  # #9b4e49
const DOCUMENT_INK := Color(0.18, 0.14, 0.11, 1.0)
const DOCUMENTS := [
	{
		"id": &"observatory-work-record",
		"title": "WORK RECORD",
		"body": "Grand Archive — Castle Observation Station\n\nTrial 18: basket service; direction dial.\n\nColumns: mass / weight / rope pull / speed change.\n\nEarlier estimate crossed out. Keep the measured result.\n\nSigned: Kath · Erin",
		"note_title": "A signed castle record",
		"note_body": "A Castle Observation Station record signed by Kath and Erin lists basket and direction trials. Its separate columns for mass, weight, rope pull and speed change were partly crossed out. The filing marks match the old library; the columns do not by themselves tell me how those quantities relate.",
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

var document_index := 0


func _ready() -> void:
	hotspots = [engine_return, records, telescope, worktable]
	state.take_spawn_tag()
	kath.position = Vector2(1465, 820)
	kath.floor_y = 820.0
	kath.left_limit = 155.0
	kath.right_limit = 1530.0
	drawer.visible = state.flags.get("observatory_drawer_open", false)
	telescope_pivot.rotation_degrees = -6.0 if state.flags.get("observatory_scope_angled", false) else 0.0
	document_modal.visible = false
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
	var closest := nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var action := "RETURN" if closest == engine_return else "INSPECT"
	if closest == records:
		action = "READ" if drawer.visible else "OPEN"
	elif closest == worktable and state.flags.get("observatory_archive_complete", false) and not state.flags.get("observatory_page_stitched", false):
		action = "STITCH"
	ui.show_prompt(closest.display_name, closest.approach_x, action, 315.0)


func _room_input(event: InputEvent) -> bool:
	if mode == &"records":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			_show_document(posmod(document_index + (-1 if event.is_action_pressed("move_left") else 1), DOCUMENTS.size()))
			return true
		if event.is_action_pressed("advance_dialogue"):
			_record_document()
			return true
	elif mode == &"stitch" and event.is_action_pressed("advance_dialogue"):
		_stitch_page()
		return true
	return false


## Until the wing is restored only the way back to the engine room is usable.
func _is_hotspot_available(hotspot: Node) -> bool:
	return hotspot == engine_return or _archive_accessible()


func _inspect(hotspot: Node) -> void:
	if hotspot == engine_return:
		_travel(ENGINE_ROOM_SCENE, &"from-observatory")
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
	_play_effect(CLICK_SOUND, CLICK_DB)
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
	document_title.add_theme_color_override("font_color", WITHDRAWN_INK if index == 2 else DOCUMENT_INK)
	document_body.text = document["body"]
	document_footer.text = "%d/3  ←/→ PAGE  %s  ESC" % [index + 1, "ENTER CLOSE" if state.has_note(document["id"]) else "ENTER NOTE"]
	document_modal.visible = true


func _record_document() -> void:
	var document: Dictionary = DOCUMENTS[document_index]
	var already_recorded: bool = state.has_note(document["id"])
	if not already_recorded:
		state.add_note_once(document["id"], document["note_title"], document["note_body"])
		_play_effect(CLICK_SOUND, CLICK_DB)
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
	state.add_note_once(&"observatory-page-stitched", "The missing leaf returned", "I stitched F = ma beside today's rope, load, speed-change and castle-stop records. The old work sheet separates mass, weight and rope pull. My working guess: F is the net force on an object, not one rope's tension; m is mass, its resistance to acceleration; a is change of velocity over time. Weight is the downward gravitational pull here. I have not compared equal net pulls with different masses or measured friction. This model still needs tests under stated conditions.")
	_play_effect(CLICK_SOUND, CLICK_DB)
	wick.react_to(1240.0, 420.0)
	_close_overlay()
	_start_dialogue(["The torn edge fits. I stitch the old page beside today's rope, load and braking observations.", "Maybe F is the combined pull on a moving thing, not the reading from one rope. The record separates mass and weight, but I still need a fair test of that idea.", "These observations and their limits belong in the notebook. I should tell Erin what the archive revealed."])


func _close_overlay() -> void:
	document_modal.visible = false
	super()
