extends Node2D
## The Hall patrol and its connection to the Machine Room.

const DRIP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/water-drop.wav")
const WARNING_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/stop-switch.wav")
const DAWN_CITY: Texture2D = preload("res://prologue-asset-pack-v1/far/archive-dawn-city.png")
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-library.wav")
const DOOR_LATCH_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/gate-latch.wav")
const WINDOW_CATCH_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const WINDOW_RATTLE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/step-wood.wav")
const CLOCK_TICK_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/clock-tick.wav")
const CLOCK_WIND_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const DOOR_FOCUS_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/door-latch-states.png")
const WINDOW_FOCUS_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/window-catch-states.png")
const CLOCK_FOCUS_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/clock-winding-detail-states.png")
const KEYS_FOCUS_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/duty-keys-states.png")
const PLAQUE_FOCUS_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/old-plaque-states.png")
const CLOCK_COVER_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/clock-inner-cover-states.png")
const CATALOGUE_TEXTURE: Texture2D = preload("res://prologue-asset-pack-v1/hall-closeups-v2/catalogue-card-states.png")
const KEY_HOOK_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const PAGE_TURN_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/page-turn.wav")

const INSPECTIONS := {
	"archive-door": {"title": "Doors and windows", "body": "The archive-door bolt and high-window catch are both fastened before the storm."},
	"clock-housing": {"title": "Hall clock", "body": "The winding handle was turned until the spring caught. The pendulum and ticking settled into a regular rhythm."},
	"duty-keys": {"title": "Duty keys", "body": "All three keys are present. I returned the east service key from a temporary nail to its labelled hook. The reverse of its tag reads OBSERVATORY CASTLE."},
	"evening-round-filed": {"title": "Evening round filed", "body": "The doors and windows, hall clock, and duty keys were checked. I stamped the completed page; the current task page is blank."},
	"emergency-procedure": {"title": "Emergency page", "body": "The red tab says: if the upper needle crosses the red line, pull lever 2, then lever 4. Check the needle again."},
	"maintenance-sheet": {"title": "Old maintenance sheet", "body": "An earlier checklist used different labels."},
	"old-plaque": {"title": "An older name", "body": "Under the dust, the archive door's nameplate reads GRAND ARCHIVE. Its current sign only says Library."},
	"clock-inner-cover": {"title": "Clock calibration marks", "body": "The clock's inner cover hides fine calibration marks and older reference lines. Someone once checked its motion more closely than a daily winding."},
	"catalogue-card": {"title": "A mismatched catalogue card", "body": "The card's current face lists Lamps, Clocks, and Keys. Its reverse uses older headings: Motion, Light, and Matter. Those headings no longer match the shelf labels."}
}

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var focus: CanvasLayer = $HallPropFocus
@onready var round_book: CanvasLayer = $HallRoundBook
@onready var archive_door: Node2D = $ArchiveDoor
@onready var high_window: Node2D = $HighWindow
@onready var door_bolt_world: Node2D = $DoorBoltWorld
@onready var window_catch_world: Node2D = $WindowCatchWorld
@onready var clock_motion: Node2D = $OldClock/ClockMotion
@onready var key_rack_world: Sprite2D = $DutyKeys/RackVisual
@onready var round_book_world: Sprite2D = $MaintenanceSheet/Sprite2D
@onready var catalogue_card_world: Sprite2D = $CatalogueCard/CardVisual
@onready var plaque_world: Sprite2D = $OldPlaqueVisual
@onready var clock_cover_world: Sprite2D = $ClockCoverVisual
@onready var upper_stacks_entry: Node2D = $UpperStacksEntry
@onready var far: Sprite2D = $Far
@onready var hotspots: Array[Node] = [$ArchiveDoor, $OldPlaque, $HighWindow, $OldClock, $ClockInnerCover, $CatalogueCard, $MaintenanceSheet, $DutyKeys, $UpperStacksEntry]
@onready var state: Node = get_node("/root/PrologueState")
@onready var notes: Array[Dictionary] = state.notes

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var pending_inspection: StringName = &""
var first_note_hint_pending := false
var one_shot_audio: AudioStreamPlayer
var completion_played := false
var focus_reaction_pending := ""
var window_rattle_audio: AudioStreamPlayer
var window_rattle_seconds := 1.8
var clock_tick_audio: AudioStreamPlayer
var clock_wind_audio: AudioStreamPlayer
var clock_tick_seconds := 1.0
var clock_winding_progress := 0.0
var clock_wind_click_stage := 0
var clock_winding_held := false
var focus_subject: StringName = &""
var focus_part := 0


func _ready() -> void:
	completion_played = bool(state.flags.get("hall_complete_line_seen", false))
	archive_door.exit_requested.connect(_on_exit_requested)
	upper_stacks_entry.exit_requested.connect(_on_exit_requested)
	focus.dismissed.connect(_on_focus_dismissed)
	round_book.dismissed.connect(_on_round_book_dismissed)
	round_book.stamped.connect(_on_round_book_stamped)
	round_book.page_turned.connect(_on_round_book_page_turned)
	one_shot_audio = AudioStreamPlayer.new()
	get_node("/root/GameSettings").configure_audio(one_shot_audio)
	one_shot_audio.name = "OneShotAudio"
	add_child(one_shot_audio)
	window_rattle_audio = AudioStreamPlayer.new()
	get_node("/root/GameSettings").configure_audio(window_rattle_audio)
	window_rattle_audio.name = "WindowRattle"
	window_rattle_audio.stream = WINDOW_RATTLE_SOUND
	window_rattle_audio.volume_db = -28.0
	add_child(window_rattle_audio)
	clock_tick_audio = AudioStreamPlayer.new()
	get_node("/root/GameSettings").configure_audio(clock_tick_audio)
	clock_tick_audio.name = "HallClockTick"
	clock_tick_audio.stream = CLOCK_TICK_SOUND
	clock_tick_audio.volume_db = -12.0
	add_child(clock_tick_audio)
	clock_wind_audio = AudioStreamPlayer.new()
	get_node("/root/GameSettings").configure_audio(clock_wind_audio)
	clock_wind_audio.name = "HallClockWinding"
	clock_wind_audio.stream = CLOCK_WIND_SOUND
	clock_wind_audio.volume_db = -9.0
	add_child(clock_wind_audio)
	clock_winding_progress = 1.0 if _clock_is_wound() else clampf(float(state.flags.get("hall_clock_winding_progress", 0.0)), 0.0, 1.0)
	clock_wind_click_stage = floori(clock_winding_progress * 4.0)
	clock_motion.set_wound(_clock_is_wound())
	clock_motion.set_winding_progress(clock_winding_progress)
	_refresh_world_latches(false)
	key_rack_world.set_sorted(_key_is_sorted(), false)
	catalogue_card_world.set_flipped(bool(state.flags.get("hall_catalogue_flipped", false)), false)
	plaque_world.set_revealed(bool(state.flags.get("hall_plaque_cleaned", false)), false)
	clock_cover_world.set_revealed(bool(state.flags.get("hall_clock_cover_open", false)), false)
	round_book_world.set_filed(bool(state.flags.get("hall_round_filed", false)), false)
	var ambience := AudioStreamPlayer.new()
	get_node("/root/GameSettings").configure_audio(ambience, true)
	ambience.name = "HallAmbience"
	ambience.stream = AMBIENCE
	ambience.volume_db = -17.0
	add_child(ambience)
	ambience.play()
	var spawn_tag: StringName = state.take_spawn_tag()
	if state.flags.get("dawn_reached", false):
		far.texture = DAWN_CITY
	if spawn_tag == &"from-machine-room":
		kath.position.x = 120.0
		if state.flags.get("incident_complete", false) and not state.flags.get("incident_return_line_seen", false):
			state.flags["incident_return_line_seen"] = true
			_start_dialogue(["The Archive drive is quiet. Through the window, the castle wing is still tilted.", "I recorded what I saw. I need to reach the Observatory Castle and find out why."])
		elif state.flags.get("machine_baseline_recorded", false) \
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
		if state.flags.get("prologue_departure_ready", false) \
			and not state.flags.get("machine_alarm_seen", false):
			state.flags["machine_alarm_seen"] = true
			state.flags["machine_incident_active"] = true
			one_shot_audio.stream = WARNING_SOUND
			one_shot_audio.volume_db = -2.0
			one_shot_audio.play()
			_start_dialogue(["That alarm is coming from the machine room! The gauge was still below the red sector last night.", "I need to get back to the controls."])
	elif not state.flags.get("hall_intro_seen", false):
		state.flags["hall_intro_seen"] = true
		_start_dialogue(["Evening rounds. Secure the door and high window, wind the clock, check the duty keys, then file the round book."])


func _exit_tree() -> void:
	if is_instance_valid(one_shot_audio):
		one_shot_audio.stop()
	var ambience := get_node_or_null("HallAmbience") as AudioStreamPlayer
	if ambience != null:
		ambience.stop()
	if is_instance_valid(window_rattle_audio):
		window_rattle_audio.stop()
	if is_instance_valid(clock_tick_audio):
		clock_tick_audio.stop()
	if is_instance_valid(clock_wind_audio):
		clock_wind_audio.stop()


func _process(delta: float) -> void:
	_update_clock_winding(delta)
	clock_tick_seconds -= delta
	if clock_tick_seconds <= 0.0:
		clock_tick_seconds = 1.12 if _clock_is_wound() else 2.7
		clock_tick_audio.play()
	if not _window_is_fixed() and mode == &"roam":
		window_rattle_seconds -= delta
		if window_rattle_seconds <= 0.0:
			window_rattle_seconds = 4.2
			window_rattle_audio.play()
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
	if mode == &"focus" and event.is_action_released("interact"):
		clock_winding_held = false
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"focus_closing":
			pass
		elif mode == &"dialogue":
			_close_dialogue(false)
		elif mode == &"paper":
			_return_from_saved_page()
		elif mode == &"focus":
			clock_winding_held = false
			_set_mode(&"focus_closing")
			focus.close_view()
		elif mode == &"round_book":
			_set_mode(&"focus_closing")
			round_book.close_view()
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
	elif mode == &"focus":
		if event.is_action_pressed("interact"):
			match focus.selected_action():
				&"secure_door_bolt":
					_secure_door_bolt()
				&"fix_window_catch":
					_fix_window_catch()
				&"wind_clock":
					clock_winding_held = true
				&"sort_duty_key":
					_sort_duty_key()
				&"wipe_plaque":
					_wipe_plaque()
				&"open_clock_cover":
					_open_clock_cover()
				&"flip_catalogue":
					_flip_catalogue()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			if focus_subject in [&"door", &"clock"]:
				_switch_focus_detail()
			else:
				focus.select_part(-1 if event.is_action_pressed("move_left") else 1)
			get_viewport().set_input_as_handled()
	elif mode == &"round_book":
		if event.is_action_pressed("interact"):
			round_book.act()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			round_book.turn(-1 if event.is_action_pressed("move_left") else 1)
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
			pending_inspection = &""
			_open_door_focus()
		&"window":
			pending_inspection = &""
			_open_window_focus()
		&"clock":
			pending_inspection = &""
			wick.react_to(967.0, 490.0)
			_open_clock_focus()
		&"keys":
			pending_inspection = &""
			wick.react_to(1370.0, 482.0)
			_open_keys_focus()
		&"sheet":
			pending_inspection = &""
			wick.react_to(1212.0, 450.0)
			ui.hide_modals()
			ui.hide_prompt()
			_set_mode(&"round_book")
			round_book.open_view(_door_is_latched(), _window_is_fixed(), _clock_is_wound(), _key_is_sorted(), bool(state.flags.get("hall_round_filed", false)))
		&"plaque":
			pending_inspection = &""
			_open_plaque_focus()
		&"clock-cover":
			pending_inspection = &""
			_open_clock_cover_focus()
		&"catalogue":
			pending_inspection = &""
			_open_catalogue_focus()
		_:
			pending_inspection = &""


func _open_door_focus() -> void:
	focus_subject = &"door"
	focus_part = 0
	ui.hide_modals()
	ui.hide_prompt()
	_set_mode(&"focus")
	focus.open_view({
		"title": "ARCHIVE DOOR · LATCH",
		"texture": DOOR_FOCUS_TEXTURE,
		"before_region": Rect2(0, 0, 887, 887),
		"after_region": Rect2(887, 0, 887, 887),
		"source": Vector2(106, 521),
		"before_text": "The bolt has slipped short of its keeper.",
		"after_text": "The bolt now sits flush in its keeper.",
		"verb": "SLIDE BOLT",
		"control_override": "E  SLIDE BOLT  ·  →  NAMEPLATE  ·  ESC  RETURN",
		"done_control": "→  NAMEPLATE",
		"parts": [{"label": "Door bolt", "action": "secure_door_bolt"}],
	}, _door_is_latched())


func _open_window_focus() -> void:
	focus_subject = &""
	ui.hide_modals()
	ui.hide_prompt()
	_set_mode(&"focus")
	focus.open_view({
		"title": "HIGH WINDOW · CATCH",
		"texture": WINDOW_FOCUS_TEXTURE,
		"before_region": Rect2(0, 0, 768, 1024),
		"after_region": Rect2(768, 0, 768, 1024),
		"source": Vector2(602, 501),
		"before_text": "The loose catch lets the frame knock in the wind.",
		"after_text": "The catch holds. The wind still moves the branches outside.",
		"verb": "PRESS CATCH",
		"done_control": "ALREADY FIXED",
		"parts": [{"label": "Window catch", "action": "fix_window_catch"}],
	}, _window_is_fixed())


func _open_clock_focus() -> void:
	focus_subject = &"clock"
	focus_part = 0
	ui.hide_modals()
	ui.hide_prompt()
	_set_mode(&"focus")
	focus.open_view({
		"title": "HALL CLOCK · WINDING HANDLE",
		"texture": CLOCK_FOCUS_TEXTURE,
		"before_region": Rect2(0, 0, 836, 941),
		"after_region": Rect2(836, 0, 836, 941),
		"source": Vector2(967, 512),
		"before_text": "The pendulum slows. The handle can wind its spring.",
		"after_text": "The handle is set. The pendulum keeps a steady rhythm.",
		"has_hold_progress": true,
		"control_override": "HOLD E  WIND SPRING  ·  →  INNER COVER  ·  ESC  RETURN",
		"done_control": "→  INNER COVER",
		"parts": [{"label": "Winding handle", "action": "wind_clock"}],
	}, _clock_is_wound())
	focus.set_hold_progress(clock_winding_progress)


func _open_keys_focus() -> void:
	focus_subject = &""
	ui.hide_modals()
	ui.hide_prompt()
	_set_mode(&"focus")
	focus.open_view({
		"title": "DUTY KEYS · EAST SERVICE WAY",
		"texture": KEYS_FOCUS_TEXTURE,
		"before_region": Rect2(0, 0, 887, 887),
		"after_region": Rect2(887, 0, 887, 887),
		"source": Vector2(1370, 506),
		"before_text": "Three keys are here. The east service key hangs on the spare nail.",
		"after_text": "The third hook is filled. The key tag has turned over.",
		"verb": "RETURN EAST KEY",
		"done_control": "THREE KEYS IN PLACE",
		"hide_parts": true,
		"hook_labels": "MACHINE ROOM\nUPPER STACKS\nEAST SERVICE WAY\nSPARE NAIL → THIRD HOOK",
		"hook_labels_after": "MACHINE ROOM\nUPPER STACKS\nEAST SERVICE WAY\nTHIRD HOOK FILLED",
		"tag_reveal": "OBSERVATORY\nCASTLE",
		"parts": [{"label": "East service key", "action": "sort_duty_key"}],
	}, _key_is_sorted())


func _open_plaque_focus() -> void:
	focus_subject = &"door"
	focus_part = 1
	ui.hide_modals()
	ui.hide_prompt()
	_set_mode(&"focus")
	focus.open_view({
		"title": "ARCHIVE DOOR · OLD NAMEPLATE",
		"texture": PLAQUE_FOCUS_TEXTURE,
		"before_region": Rect2(0, 0, 887, 887),
		"after_region": Rect2(887, 0, 887, 887),
		"source": Vector2(162, 550),
		"before_text": "Dust covers the older plate beside the bolt.",
		"after_text": "The uncovered brass reads GRAND ARCHIVE.",
		"verb": "WIPE DUST",
		"control_override": "E  WIPE DUST  ·  ←  DOOR BOLT  ·  ESC  RETURN",
		"done_control": "←  DOOR BOLT",
		"hide_parts": true,
		"inscription_after": "GRAND\nARCHIVE",
		"inscription_position": Vector2(955, 479),
		"inscription_size": Vector2(176, 71),
		"inscription_font_size": 23,
		"inscription_color": Color("47322a"),
		"parts": [{"label": "Dusty plate", "action": "wipe_plaque"}],
	}, bool(state.flags.get("hall_plaque_cleaned", false)))


func _open_clock_cover_focus() -> void:
	focus_subject = &"clock"
	focus_part = 1
	ui.hide_modals()
	ui.hide_prompt()
	_set_mode(&"focus")
	focus.open_view({
		"title": "HALL CLOCK · INNER COVER",
		"texture": CLOCK_COVER_TEXTURE,
		"before_region": Rect2(0, 0, 887, 887),
		"after_region": Rect2(887, 0, 887, 887),
		"source": Vector2(970, 555),
		"before_text": "A small brass cover is fitted below the pendulum.",
		"after_text": "Fine calibration marks are etched inside the cover.",
		"verb": "OPEN COVER",
		"control_override": "E  OPEN COVER  ·  ←  CLOCK HANDLE  ·  ESC  RETURN",
		"done_control": "←  CLOCK HANDLE",
		"hide_parts": true,
		"parts": [{"label": "Inner cover", "action": "open_clock_cover"}],
	}, bool(state.flags.get("hall_clock_cover_open", false)))


func _open_catalogue_focus() -> void:
	focus_subject = &""
	ui.hide_modals()
	ui.hide_prompt()
	_set_mode(&"focus")
	focus.open_view({
		"title": "DUTY DESK · CATALOGUE CARD",
		"texture": CATALOGUE_TEXTURE,
		"before_region": Rect2(0, 0, 836, 941),
		"after_region": Rect2(836, 0, 836, 941),
		"source": Vector2(1114, 598),
		"before_text": "The front lists the shelves used in today's rounds.",
		"after_text": "The reverse has older headings that the shelves no longer use.",
		"verb": "FLIP CARD",
		"done_control": "REVERSE EXAMINED",
		"hide_parts": true,
		"transition": "flip",
		"inscription_before": "CURRENT SHELVES\nLAMPS  ·  CLOCKS  ·  KEYS",
		"inscription_after": "OLD INDEX\nMOTION  ·  LIGHT  ·  MATTER",
		"inscription_position": Vector2(656, 377),
		"inscription_size": Vector2(362, 184),
		"inscription_font_size": 23,
		"inscription_color": Color("493d40"),
		"parts": [{"label": "Catalogue card", "action": "flip_catalogue"}],
	}, bool(state.flags.get("hall_catalogue_flipped", false)))


func _switch_focus_detail() -> void:
	if focus.transitioning:
		return
	clock_winding_held = false
	if focus_subject == &"door":
		if focus_part == 0:
			_open_plaque_focus()
		else:
			_open_door_focus()
	elif focus_subject == &"clock":
		if focus_part == 0:
			_open_clock_cover_focus()
		else:
			_open_clock_focus()


func _wipe_plaque() -> void:
	if state.flags.get("hall_plaque_cleaned", false):
		return
	state.flags["hall_plaque_cleaned"] = true
	focus.set_completed()
	plaque_world.set_revealed(true)
	one_shot_audio.stream = PAGE_TURN_SOUND
	one_shot_audio.play()
	_record(&"old-plaque", false)
	focus_reaction_pending = "Grand Archive? I've only ever known this place as the library."


func _open_clock_cover() -> void:
	if state.flags.get("hall_clock_cover_open", false):
		return
	state.flags["hall_clock_cover_open"] = true
	focus.set_completed()
	clock_cover_world.set_revealed(true)
	one_shot_audio.stream = KEY_HOOK_SOUND
	one_shot_audio.play()
	_record(&"clock-inner-cover", false)
	focus_reaction_pending = "These marks are much finer than the ones I use to set the hour."


func _flip_catalogue() -> void:
	if state.flags.get("hall_catalogue_flipped", false):
		return
	state.flags["hall_catalogue_flipped"] = true
	focus.set_completed()
	catalogue_card_world.set_flipped(true)
	one_shot_audio.stream = PAGE_TURN_SOUND
	one_shot_audio.play()
	_record(&"catalogue-card", false)
	focus_reaction_pending = "Motion, Light, Matter... None of those are shelf labels now. Why keep this card?"


func _sort_duty_key() -> void:
	if _key_is_sorted():
		return
	state.flags["hall_east_key_sorted"] = true
	focus.set_completed()
	key_rack_world.set_sorted(true)
	one_shot_audio.stream = KEY_HOOK_SOUND
	one_shot_audio.play()
	_record(&"duty-keys", false)
	focus_reaction_pending = "All three are accounted for. Why does the east key's old tag say Observatory Castle?"


func _key_is_sorted() -> bool:
	return bool(state.flags.get("hall_east_key_sorted", false)) or state.has_note(&"duty-keys")


func _update_clock_winding(delta: float) -> void:
	if mode != &"focus" or not clock_winding_held or _clock_is_wound():
		return
	clock_winding_progress = minf(1.0, clock_winding_progress + delta)
	state.flags["hall_clock_winding_progress"] = clock_winding_progress
	clock_motion.set_winding_progress(clock_winding_progress)
	focus.set_hold_progress(clock_winding_progress)
	var next_stage := floori(clock_winding_progress * 4.0)
	if next_stage > clock_wind_click_stage:
		clock_wind_click_stage = next_stage
		clock_wind_audio.play()
	if clock_winding_progress >= 1.0:
		_complete_clock_winding()


func _complete_clock_winding() -> void:
	if _clock_is_wound():
		return
	clock_winding_held = false
	clock_winding_progress = 1.0
	state.flags["hall_clock_winding_progress"] = 1.0
	state.flags["hall_clock_wound"] = true
	focus.set_completed()
	clock_motion.set_wound(true)
	clock_tick_seconds = 0.2
	_record(&"clock-housing", false)
	focus_reaction_pending = "The pendulum is steady again. I'll mark the clock as wound."


func _clock_is_wound() -> bool:
	return bool(state.flags.get("hall_clock_wound", false)) or state.has_note(&"clock-housing")


func _secure_door_bolt() -> void:
	if _door_is_latched():
		return
	state.flags["hall_door_latched"] = true
	focus.set_completed()
	_refresh_world_latches()
	one_shot_audio.stream = DOOR_LATCH_SOUND
	one_shot_audio.play()
	_try_record_door_window()
	focus_reaction_pending = "The bolt caught. The door should hold when the wind rises." if not _window_is_fixed() else "The bolt caught. The door and window are both secure."


func _fix_window_catch() -> void:
	if _window_is_fixed():
		return
	state.flags["hall_window_fixed"] = true
	focus.set_completed()
	_refresh_world_latches()
	window_rattle_audio.stop()
	one_shot_audio.stream = WINDOW_CATCH_SOUND
	one_shot_audio.play()
	_try_record_door_window()
	focus_reaction_pending = "The frame is quiet now. The wind outside hasn't stopped." if not _door_is_latched() else "The frame is quiet. Both the door and window are secure."


func _door_is_latched() -> bool:
	return bool(state.flags.get("hall_door_latched", false)) or state.has_note(&"archive-door")


func _window_is_fixed() -> bool:
	return bool(state.flags.get("hall_window_fixed", false)) or state.has_note(&"archive-door")


func _try_record_door_window() -> void:
	if _door_is_latched() and _window_is_fixed():
		_record(&"archive-door", false)


func _refresh_world_latches(animate: bool = true) -> void:
	door_bolt_world.set_secured(_door_is_latched(), animate)
	window_catch_world.set_secured(_window_is_fixed(), animate)


func _on_focus_dismissed() -> void:
	clock_winding_held = false
	focus_subject = &""
	_set_mode(&"roam")
	if not focus_reaction_pending.is_empty():
		var line := focus_reaction_pending
		focus_reaction_pending = ""
		_start_dialogue([line])
	else:
		_maybe_finish_hall()
	_show_pending_note_hint()


func _on_round_book_stamped() -> void:
	if state.flags.get("hall_round_filed", false):
		return
	state.flags["hall_round_filed"] = true
	round_book_world.set_filed(true)
	one_shot_audio.stream = KEY_HOOK_SOUND
	one_shot_audio.play()
	_record(&"evening-round-filed", false)


func _on_round_book_page_turned(page_name: StringName) -> void:
	one_shot_audio.stream = PAGE_TURN_SOUND
	one_shot_audio.play()
	if page_name == &"emergency" and not state.has_note(&"emergency-procedure"):
		_record(&"emergency-procedure", false)


func _on_round_book_dismissed() -> void:
	_set_mode(&"roam")
	_maybe_finish_hall()
	_show_pending_note_hint()


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


func _close_modal() -> void:
	if mode == &"dialogue":
		pending_inspection = &""
	ui.hide_modals()
	_set_mode(&"roam")


func _show_journal() -> void:
	ui.show_journal(notes, state.hall_checks_complete(), bool(state.flags.get("machine_baseline_recorded", false)), bool(state.flags.get("stacks_bucket_moved", false)), bool(state.flags.get("stacks_page_collected", false)), bool(state.flags.get("room_notebook_compared", false)), bool(state.flags.get("incident_complete", false)), state.room_preparation_complete(), bool(state.flags.get("machine_incident_active", false)))


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
		_start_dialogue(["The round is filed. I should record the machine-room reading before I investigate the upper shelves."])


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
