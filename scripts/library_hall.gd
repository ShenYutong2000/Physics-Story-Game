extends StoryRoom
## The Hall patrol and its connection to the Machine Room.

const MACHINE_SCENE := "res://scenes/machine_room.tscn"
const UPPER_SCENE := "res://scenes/upper_stacks.tscn"
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-library.wav")
const DRIP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/water-drop.wav")
const WARNING_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/stop-switch.wav")
const DOOR_LATCH_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/gate-latch.wav")
const CLICK_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const WINDOW_RATTLE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/step-wood.wav")
const CLOCK_TICK_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/clock-tick.wav")
const PAGE_TURN_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/page-turn.wav")
const CLOSEUPS := "res://prologue-asset-pack-v1/hall-closeups-v2/"

const INSPECTIONS := {
	&"archive-door": {"title": "Doors and windows", "body": "The archive-door bolt and high-window catch are both fastened before the storm."},
	&"clock-housing": {"title": "Hall clock", "body": "The winding handle was turned until the spring caught. The pendulum and ticking settled into a regular rhythm."},
	&"duty-keys": {"title": "Duty keys", "body": "All three keys are present. I returned the east service key from a temporary nail to its labelled hook. The reverse of its tag reads OBSERVATORY CASTLE."},
	&"evening-round-filed": {"title": "Evening round filed", "body": "The doors and windows, hall clock, and duty keys were checked. I stamped the completed page; the current task page is blank."},
	&"emergency-procedure": {"title": "Emergency page", "body": "The red tab says: if the upper needle crosses the red line, pull lever 2, then lever 4. Check the needle again."},
	&"old-plaque": {"title": "An older name", "body": "Under the dust, the archive door's nameplate reads GRAND ARCHIVE. Its current sign only says Library."},
	&"clock-inner-cover": {"title": "Clock calibration marks", "body": "The clock's inner cover hides fine calibration marks and older reference lines. Someone once checked its motion more closely than a daily winding."},
	&"catalogue-card": {"title": "A mismatched catalogue card", "body": "The card's current face lists Lamps, Clocks, and Keys. Its reverse uses older headings: Motion, Light, and Matter. Those headings no longer match the shelf labels."},
}

## Close-up views. "subject"/"part" pair views the player can switch between
## with Left/Right (door bolt <-> nameplate, clock handle <-> inner cover).
const FOCUS_VIEWS := {
	&"door": {"subject": &"door", "part": 0, "view": {
		"title": "ARCHIVE DOOR · LATCH",
		"texture": preload(CLOSEUPS + "door-latch-states.png"),
		"before_region": Rect2(0, 0, 887, 887),
		"after_region": Rect2(887, 0, 887, 887),
		"source": Vector2(106, 521),
		"before_text": "The bolt has slipped short of its keeper.",
		"after_text": "The bolt now sits flush in its keeper.",
		"verb": "SLIDE BOLT",
		"control_override": "E  SLIDE BOLT  ·  →  NAMEPLATE  ·  ESC  RETURN",
		"done_control": "→  NAMEPLATE",
		"parts": [{"label": "Door bolt", "action": "secure_door_bolt"}],
	}},
	&"plaque": {"subject": &"door", "part": 1, "view": {
		"title": "ARCHIVE DOOR · OLD NAMEPLATE",
		"texture": preload(CLOSEUPS + "old-plaque-states.png"),
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
		"inscription_color": Color(71 / 255.0, 50 / 255.0, 42 / 255.0),
		"parts": [{"label": "Dusty plate", "action": "wipe_plaque"}],
	}},
	&"window": {"subject": &"", "part": 0, "view": {
		"title": "HIGH WINDOW · CATCH",
		"texture": preload(CLOSEUPS + "window-catch-states.png"),
		"before_region": Rect2(0, 0, 768, 1024),
		"after_region": Rect2(768, 0, 768, 1024),
		"source": Vector2(602, 501),
		"before_text": "The loose catch lets the frame knock in the wind.",
		"after_text": "The catch holds. The wind still moves the branches outside.",
		"verb": "PRESS CATCH",
		"done_control": "ALREADY FIXED",
		"parts": [{"label": "Window catch", "action": "fix_window_catch"}],
	}},
	&"clock": {"subject": &"clock", "part": 0, "view": {
		"title": "HALL CLOCK · WINDING HANDLE",
		"texture": preload(CLOSEUPS + "clock-winding-detail-states.png"),
		"before_region": Rect2(0, 0, 836, 941),
		"after_region": Rect2(836, 0, 836, 941),
		"source": Vector2(967, 512),
		"before_text": "The pendulum slows. The handle can wind its spring.",
		"after_text": "The handle is set. The pendulum keeps a steady rhythm.",
		"has_hold_progress": true,
		"control_override": "HOLD E  WIND SPRING  ·  →  INNER COVER  ·  ESC  RETURN",
		"done_control": "→  INNER COVER",
		"parts": [{"label": "Winding handle", "action": "wind_clock"}],
	}},
	&"clock-cover": {"subject": &"clock", "part": 1, "view": {
		"title": "HALL CLOCK · INNER COVER",
		"texture": preload(CLOSEUPS + "clock-inner-cover-states.png"),
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
	}},
	&"keys": {"subject": &"", "part": 0, "view": {
		"title": "DUTY KEYS · EAST SERVICE WAY",
		"texture": preload(CLOSEUPS + "duty-keys-states.png"),
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
	}},
	&"catalogue": {"subject": &"", "part": 0, "view": {
		"title": "DUTY DESK · CATALOGUE CARD",
		"texture": preload(CLOSEUPS + "catalogue-card-states.png"),
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
		"inscription_color": Color(73 / 255.0, 61 / 255.0, 64 / 255.0),
		"parts": [{"label": "Catalogue card", "action": "flip_catalogue"}],
	}},
}
## Where Wick looks when Kath opens a close-up.
const WICK_FOCUS_TARGETS := {&"clock": Vector2(967, 490), &"keys": Vector2(1370, 482), &"sheet": Vector2(1212, 450)}

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
@onready var rain_streaks: Node2D = $RainStreaks

var first_note_hint_pending := false
var completion_played := false
var focus_reaction_pending := ""
var focus_subject: StringName = &""
var focus_part := 0
var window_rattle_audio: AudioStreamPlayer
var window_rattle_seconds := 1.8
var clock_tick_audio: AudioStreamPlayer
var clock_wind_audio: AudioStreamPlayer
var clock_tick_seconds := 1.0
var clock_winding_progress := 0.0
var clock_wind_click_stage := 0
var clock_winding_held := false


func _ready() -> void:
	hotspots = [archive_door, $OldPlaque, high_window, $OldClock, $ClockInnerCover, $CatalogueCard, $MaintenanceSheet, $DutyKeys, upper_stacks_entry]
	completion_played = _flag("hall_complete_line_seen")
	archive_door.exit_requested.connect(_on_exit_requested)
	upper_stacks_entry.exit_requested.connect(_on_exit_requested)
	focus.dismissed.connect(_on_focus_dismissed)
	round_book.dismissed.connect(_on_round_book_dismissed)
	round_book.stamped.connect(_on_round_book_stamped)
	round_book.page_turned.connect(_on_round_book_page_turned)
	window_rattle_audio = _add_audio("WindowRattle", WINDOW_RATTLE_SOUND, -28.0)
	clock_tick_audio = _add_audio("HallClockTick", CLOCK_TICK_SOUND, -12.0)
	clock_wind_audio = _add_audio("HallClockWinding", CLICK_SOUND, -9.0)
	_add_audio("HallAmbience", AMBIENCE, -17.0, true)
	clock_winding_progress = 1.0 if _clock_is_wound() else clampf(float(state.flags.get("hall_clock_winding_progress", 0.0)), 0.0, 1.0)
	clock_wind_click_stage = floori(clock_winding_progress * 4.0)
	clock_motion.set_wound(_clock_is_wound())
	clock_motion.set_winding_progress(clock_winding_progress)
	_refresh_world_latches(false)
	key_rack_world.set_sorted(_key_is_sorted(), false)
	catalogue_card_world.set_flipped(_flag("hall_catalogue_flipped"), false)
	plaque_world.set_revealed(_flag("hall_plaque_cleaned"), false)
	clock_cover_world.set_revealed(_flag("hall_clock_cover_open"), false)
	round_book_world.set_filed(_flag("hall_round_filed"), false)
	var spawn_tag: StringName = state.take_spawn_tag()
	if spawn_tag == &"from-machine-room" and _flag("machine_baseline_recorded") and not _flag("dawn_reached"):
		state.flags["hall_rain_heavy"] = true
	_apply_archive_weather(far, rain_streaks)
	if spawn_tag == &"from-machine-room":
		kath.position.x = 120.0
		_play_machine_return_cue()
	elif spawn_tag == &"from-upper-stacks":
		kath.position.x = 1530.0
		if _flag("prologue_departure_ready") and not _flag("machine_alarm_seen"):
			state.flags["machine_alarm_seen"] = true
			state.flags["machine_incident_active"] = true
			_play_effect(WARNING_SOUND, -2.0)
			_start_dialogue(["That alarm is coming from the machine room! The gauge was still below the red sector last night.", "I need to get back to the controls."])
	elif not _flag("hall_intro_seen"):
		state.flags["hall_intro_seen"] = true
		_start_dialogue(["A storm is building. I'll secure the door and high window, wind the clock, check the keys, then file the round book."])


func _play_machine_return_cue() -> void:
	if _flag("incident_complete") and not _flag("incident_return_line_seen"):
		state.flags["incident_return_line_seen"] = true
		_start_dialogue(["The Archive drive is quiet. Through the window, the castle wing is still tilted.", "I recorded what I saw. I need to reach the Observatory Castle and find out why."])
	elif _flag("machine_baseline_recorded") and not _flag("hall_return_cue_seen"):
		state.flags["hall_return_cue_seen"] = true
		_play_effect(DRIP_SOUND)
		_start_dialogue(["The storm has strengthened. A drop just fell from the ceiling above the upper stacks.", "The machine reading is safe for now. I should check where that water is coming from."])
	elif not _flag("early_return_cue_seen"):
		state.flags["early_return_cue_seen"] = true
		_start_dialogue(["Rain has started outside. I haven't written down the machine-room reading yet; the service stairs are still open."])


func _flag(key: String) -> bool:
	return bool(state.flags.get(key, false))


func _process(delta: float) -> void:
	_update_clock_winding(delta)
	clock_tick_seconds -= delta
	if clock_tick_seconds <= 0.0:
		clock_tick_seconds = 1.12 if _clock_is_wound() else 2.7
		clock_tick_audio.play()
	if mode != &"roam":
		ui.hide_prompt()
		return
	if not _window_is_fixed():
		window_rattle_seconds -= delta
		if window_rattle_seconds <= 0.0:
			window_rattle_seconds = 4.2
			window_rattle_audio.play()
	var hall_complete: bool = state.hall_checks_complete()
	var stacks_open: bool = state.upper_stacks_unlocked()
	archive_door.display_name = "Machine Room" if hall_complete else "Archive door"
	upper_stacks_entry.display_name = "Upper Stacks" if stacks_open else "Upper Stacks (inspect)"
	var closest := nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var can_enter := (closest == archive_door and hall_complete) or (closest == upper_stacks_entry and stacks_open)
	ui.show_prompt(closest.display_name, closest.approach_x, "ENTER" if can_enter else "INSPECT")


# --- Input -------------------------------------------------------------------

func _room_input(event: InputEvent) -> bool:
	match mode:
		&"focus":
			if event.is_action_released("interact"):
				clock_winding_held = false
				return true
			if event.is_action_pressed("interact"):
				_run_focus_action(focus.selected_action())
				return true
			if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
				if focus_subject in [&"door", &"clock"]:
					_switch_focus_detail()
				else:
					focus.select_part(-1 if event.is_action_pressed("move_left") else 1)
				return true
		&"round_book":
			if event.is_action_pressed("interact"):
				round_book.act()
				return true
			if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
				round_book.turn(-1 if event.is_action_pressed("move_left") else 1)
				return true
	return false


func _cancel() -> void:
	match mode:
		&"focus":
			clock_winding_held = false
			_set_mode(&"focus_closing")
			focus.close_view()
		&"round_book":
			_set_mode(&"focus_closing")
			round_book.close_view()
		&"focus_closing":
			pass
		_:
			super()


func _run_focus_action(action: StringName) -> void:
	match action:
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


# --- Hotspots and close-ups ----------------------------------------------------

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
	var view: StringName = hotspot.content_key
	if WICK_FOCUS_TARGETS.has(view):
		var target: Vector2 = WICK_FOCUS_TARGETS[view]
		wick.react_to(target.x, target.y)
	if view == &"sheet":
		ui.hide_modals()
		ui.hide_prompt()
		_set_mode(&"round_book")
		round_book.open_view(_door_is_latched(), _window_is_fixed(), _clock_is_wound(), _key_is_sorted(), _flag("hall_round_filed"))
	elif FOCUS_VIEWS.has(view):
		_open_focus(view)


func _open_focus(view: StringName) -> void:
	var entry: Dictionary = FOCUS_VIEWS[view]
	focus_subject = entry["subject"]
	focus_part = entry["part"]
	ui.hide_modals()
	ui.hide_prompt()
	_set_mode(&"focus")
	focus.open_view(entry["view"], _focus_done(view))
	if view == &"clock":
		focus.set_hold_progress(clock_winding_progress)


func _focus_done(view: StringName) -> bool:
	match view:
		&"door":
			return _door_is_latched()
		&"window":
			return _window_is_fixed()
		&"clock":
			return _clock_is_wound()
		&"keys":
			return _key_is_sorted()
		&"plaque":
			return _flag("hall_plaque_cleaned")
		&"clock-cover":
			return _flag("hall_clock_cover_open")
		&"catalogue":
			return _flag("hall_catalogue_flipped")
	return false


func _switch_focus_detail() -> void:
	if focus.transitioning:
		return
	clock_winding_held = false
	if focus_subject == &"door":
		_open_focus(&"plaque" if focus_part == 0 else &"door")
	elif focus_subject == &"clock":
		_open_focus(&"clock-cover" if focus_part == 0 else &"clock")


## Shared ending for a close-up action: mark it done, play its sound and
## queue Kath's line for when the close-up is dismissed.
func _finish_focus_action(sound: AudioStream, note_id: StringName, reaction: String) -> void:
	focus.set_completed()
	if sound != null:
		_play_effect(sound)
	if note_id != &"":
		_record(note_id, false)
	focus_reaction_pending = reaction


func _wipe_plaque() -> void:
	if _flag("hall_plaque_cleaned"):
		return
	state.flags["hall_plaque_cleaned"] = true
	plaque_world.set_revealed(true)
	_finish_focus_action(PAGE_TURN_SOUND, &"old-plaque", "Grand Archive? I've only ever known this place as the library.")


func _open_clock_cover() -> void:
	if _flag("hall_clock_cover_open"):
		return
	state.flags["hall_clock_cover_open"] = true
	clock_cover_world.set_revealed(true)
	_finish_focus_action(CLICK_SOUND, &"clock-inner-cover", "These marks are much finer than the ones I use to set the hour.")


func _flip_catalogue() -> void:
	if _flag("hall_catalogue_flipped"):
		return
	state.flags["hall_catalogue_flipped"] = true
	catalogue_card_world.set_flipped(true)
	_finish_focus_action(PAGE_TURN_SOUND, &"catalogue-card", "Motion, Light, Matter... None of those are shelf labels now. Why keep this card?")


func _sort_duty_key() -> void:
	if _key_is_sorted():
		return
	state.flags["hall_east_key_sorted"] = true
	key_rack_world.set_sorted(true)
	_finish_focus_action(CLICK_SOUND, &"duty-keys", "All three are accounted for. Why does the east key's old tag say Observatory Castle?")


func _secure_door_bolt() -> void:
	if _door_is_latched():
		return
	state.flags["hall_door_latched"] = true
	_refresh_world_latches()
	_finish_focus_action(DOOR_LATCH_SOUND, &"", "The bolt caught. The door and window are both secure." if _window_is_fixed() else "The bolt caught. The door should hold when the wind rises.")
	_try_record_door_window()


func _fix_window_catch() -> void:
	if _window_is_fixed():
		return
	state.flags["hall_window_fixed"] = true
	_refresh_world_latches()
	window_rattle_audio.stop()
	_finish_focus_action(CLICK_SOUND, &"", "The frame is quiet. Both the door and window are secure." if _door_is_latched() else "The frame is quiet now. The wind outside hasn't stopped.")
	_try_record_door_window()


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
	clock_motion.set_wound(true)
	clock_tick_seconds = 0.2
	_finish_focus_action(null, &"clock-housing", "The pendulum is steady again. I'll mark the clock as wound.")


# A note from an earlier save also counts as the check being done.
func _door_is_latched() -> bool:
	return _flag("hall_door_latched") or state.has_note(&"archive-door")


func _window_is_fixed() -> bool:
	return _flag("hall_window_fixed") or state.has_note(&"archive-door")


func _clock_is_wound() -> bool:
	return _flag("hall_clock_wound") or state.has_note(&"clock-housing")


func _key_is_sorted() -> bool:
	return _flag("hall_east_key_sorted") or state.has_note(&"duty-keys")


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
	if focus_reaction_pending.is_empty():
		_maybe_finish_hall()
	else:
		var line := focus_reaction_pending
		focus_reaction_pending = ""
		_start_dialogue([line])
	_show_pending_note_hint()


func _on_round_book_stamped() -> void:
	if _flag("hall_round_filed"):
		return
	state.flags["hall_round_filed"] = true
	round_book_world.set_filed(true)
	_play_effect(CLICK_SOUND)
	_record(&"evening-round-filed", false)


func _on_round_book_page_turned(page_name: StringName) -> void:
	_play_effect(PAGE_TURN_SOUND)
	if page_name == &"emergency" and not state.has_note(&"emergency-procedure"):
		_record(&"emergency-procedure", false)


func _on_round_book_dismissed() -> void:
	_set_mode(&"roam")
	_maybe_finish_hall()
	_show_pending_note_hint()


# --- Notes and patrol completion ---------------------------------------------

func _close_dialogue(completed: bool) -> void:
	super(completed)
	if completed:
		_maybe_finish_hall()
	_show_pending_note_hint()


func _record(inspection_id: StringName, show_completion: bool = true) -> void:
	var item: Dictionary = INSPECTIONS[inspection_id]
	var added: bool = state.add_note_once(inspection_id, item["title"], item["body"])
	if added and state.notes.filter(func(entry: Dictionary) -> bool: return entry["id"] in state.HALL_NOTE_IDS).size() == 1:
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


func _on_exit_requested(destination_scene: String, spawn_tag: String) -> void:
	if destination_scene == MACHINE_SCENE:
		if not state.hall_checks_complete():
			return
		if not _flag("dawn_reached"):
			state.flags["hall_rain_started"] = true
	elif destination_scene == UPPER_SCENE and not state.upper_stacks_unlocked():
		return
	state.travel_to(destination_scene, StringName(spawn_tag))
