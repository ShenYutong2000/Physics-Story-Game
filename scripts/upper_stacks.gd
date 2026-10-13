extends Node2D
## Exploration, leak response, and the rolling ladder in the Upper Stacks.

const HALL_SCENE := "res://scenes/library_hall.tscn"
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-room.wav")
const DRIP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/water-drop.wav")
const CASE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/case-open.wav")
const LADDER_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/ladder-step.wav")
const PAGE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/page-turn.wav")
const PENCIL_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/pencil-write.wav")
const LEAK_NOTE := "Rain slips through a roof seam above the stacks. Moving a bucket beneath the falling water stopped it reaching the floor."
const NEWTON_NOTE := "A torn page reads F = ma. The measurements are crossed out and repeated. At the bottom: ‘Next time at the castle, try again.’ The handwriting is Kath's."

const FLOOR_Y := 708.0
const LADDER_START_X := 1198.0
const LADDER_MIN_X := 800.0
const LADDER_MAX_X := 1430.0
const CASE_X := 1012.0
const LEAK_X := 1410.0
const RETURN_X := 500.0

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var ladder: Sprite2D = $RollingLadder
@onready var case_sprite: AnimatedSprite2D = $WoodenCase/AnimatedSprite2D
@onready var bucket: Sprite2D = $Bucket
@onready var ripple: AnimatedSprite2D = $Ripple
@onready var rain_drop: Sprite2D = $RainDrop
@onready var state: Node = get_node("/root/PrologueState")

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var page_from_journal := false
var drip_player: AudioStreamPlayer
var effects_player: AudioStreamPlayer
var drip_timer := 0.0
var drop_elapsed := 0.0
var has_climbed_above_floor := false
var leak_inspected := false
var case_open := false


func _ready() -> void:
	var spawn_tag: StringName = state.take_spawn_tag()
	kath.position = Vector2(RETURN_X, FLOOR_Y)
	if spawn_tag == &"from-hall":
		kath.position.x = RETURN_X
	elif spawn_tag == &"from-upper-stacks":
		kath.position.x = 1530.0

	ladder.position.x = float(state.flags.get("stacks_ladder_x", LADDER_START_X))
	ladder.position.y = FLOOR_Y
	case_sprite.frame = 2 if state.flags.get("stacks_page_collected", false) else (1 if state.flags.get("stacks_case_open", false) else 0)
	bucket.position = Vector2(LEAK_X if state.flags.get("stacks_bucket_moved", false) else 900.0, FLOOR_Y - 48.0)
	case_open = bool(state.flags.get("stacks_case_open", false))
	ripple_setup()

	var ambience := AudioStreamPlayer.new()
	ambience.name = "UpperStacksAmbience"
	ambience.stream = AMBIENCE
	ambience.volume_db = -16.0
	add_child(ambience)
	ambience.play()
	drip_player = AudioStreamPlayer.new()
	drip_player.name = "DripAudio"
	drip_player.stream = DRIP_SOUND
	drip_player.volume_db = -11.0
	add_child(drip_player)
	effects_player = AudioStreamPlayer.new()
	effects_player.name = "EffectsAudio"
	add_child(effects_player)
	if spawn_tag == &"from-hall" and not state.flags.get("stacks_intro_seen", false):
		state.flags["stacks_intro_seen"] = true
		_start_dialogue(["There. A roof seam above the shelves.", "I'll put the bucket where the drops are landing, then find a safe way to reach that top row."])


func _exit_tree() -> void:
	if is_instance_valid(drip_player):
		drip_player.stop()
	if is_instance_valid(effects_player):
		effects_player.stop()
	var ambience := get_node_or_null("UpperStacksAmbience") as AudioStreamPlayer
	if ambience != null:
		ambience.stop()


func _process(delta: float) -> void:
	if not state.flags.get("stacks_bucket_moved", false):
		drop_elapsed = fposmod(drop_elapsed + delta, 1.25)
		rain_drop.position = Vector2(LEAK_X, 282.0 + (drop_elapsed / 1.25) * 352.0)
		rain_drop.modulate.a = 1.0 if drop_elapsed < 1.12 else 1.0 - (drop_elapsed - 1.12) / 0.13
	else:
		rain_drop.visible = false
	if kath.locomotion_mode == &"push":
		ladder.position.x = clampf(kath.position.x + 72.0, LADDER_MIN_X, LADDER_MAX_X)
		state.flags["stacks_ladder_x"] = ladder.position.x
	if kath.locomotion_mode == &"climb" and kath.position.y < FLOOR_Y - 5.0:
		has_climbed_above_floor = true
	var reached_floor_while_climbing := kath.position.y >= FLOOR_Y - 0.1 \
		and (has_climbed_above_floor or Input.is_action_pressed("move_down"))
	if kath.locomotion_mode == &"climb" and reached_floor_while_climbing:
		kath.stop_climbing()
		has_climbed_above_floor = false
		_play_effect(LADDER_SOUND)
	if not state.flags.get("stacks_bucket_moved", false):
		drip_timer -= delta
		if drip_timer <= 0.0 and not drip_player.playing:
			drip_player.play()
			drip_timer = 1.7
	if mode != &"roam":
		ui.hide_prompt()
		return
	if kath.locomotion_mode == &"push":
		ui.hide_prompt()
		return
	var feet_x := kath.position.x
	if kath.locomotion_mode == &"climb":
		if _can_open_case():
			ui.show_prompt("Wooden case", CASE_X, "OPEN CASE", kath.position.y - 120.0)
		else:
			ui.hide_prompt()
		return
	if absf(feet_x - RETURN_X) <= 112.0:
		ui.show_prompt("Stairway to Hall", RETURN_X, "RETURN", 260.0)
	elif absf(feet_x - LEAK_X) <= 125.0 and not state.flags.get("stacks_bucket_moved", false):
		ui.show_prompt("Roof seam", LEAK_X, "MOVE BUCKET" if leak_inspected else "INSPECT", 238.0)
	elif absf(feet_x - ladder.position.x) <= 112.0:
		var ladder_aligned := absf(ladder.position.x - CASE_X) <= 80.0
		var can_climb: bool = bool(state.flags.get("stacks_ladder_locked", true)) \
			and (state.flags.get("stacks_ladder_ready_to_climb", false) or ladder_aligned)
		var ladder_action := "CLIMB" if can_climb else "PUSH LADDER"
		ui.show_prompt("Rolling ladder", ladder.position.x, ladder_action, 440.0)
	elif absf(feet_x - CASE_X) <= 105.0 and absf(ladder.position.x - CASE_X) > 80.0:
		ui.show_prompt("High shelf", CASE_X, "LADDER TOO FAR", 258.0)
	else:
		ui.hide_prompt()


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
			if page_from_journal:
				_return_to_journal()
			else:
				_close_paper(false)
		else:
			_close_modal()
		get_viewport().set_input_as_handled()
		return
	if mode == &"roam":
		if event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_handle_interact()
		elif event.is_action_pressed("toggle_journal"):
			_set_mode(&"journal")
			_show_journal()
			get_viewport().set_input_as_handled()
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		_advance_dialogue()
		get_viewport().set_input_as_handled()
	elif mode == &"paper" and event.is_action_pressed("advance_dialogue"):
		if page_from_journal:
			_return_to_journal()
		else:
			_close_paper(true)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("toggle_journal"):
		_close_modal()
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("advance_dialogue") and state.has_note(&"newton-note"):
		page_from_journal = true
		_set_mode(&"paper")
		ui.show_torn_page(true)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("move_up"):
		ui.scroll_journal(-1)
		get_viewport().set_input_as_handled()
	elif mode == &"journal" and event.is_action_pressed("move_down"):
		ui.scroll_journal(1)
		get_viewport().set_input_as_handled()
	elif mode == &"paused":
		if event.is_action_pressed("advance_dialogue"):
			_close_modal()
			get_viewport().set_input_as_handled()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_Q:
			get_tree().quit()


func _handle_interact() -> void:
	var x := kath.position.x
	if kath.locomotion_mode == &"climb":
		if _can_open_case():
			_interact_case()
		return
	if kath.locomotion_mode == &"push":
		_end_ladder_push()
		return
	if x < 610.0 and kath.locomotion_mode == &"walk":
		state.travel_to(HALL_SCENE, &"from-upper-stacks")
		return
	if absf(x - LEAK_X) <= 125.0 and not state.flags.get("stacks_bucket_moved", false):
		if not leak_inspected:
			leak_inspected = true
			wick.react_to(LEAK_X - 20.0, 342.0)
			_start_dialogue(["The water is falling in a narrow line from that split in the roof.", "The bucket is close enough to slide beneath it."])
		else:
			state.flags["stacks_bucket_moved"] = true
			bucket.position = Vector2(LEAK_X, FLOOR_Y - 48.0)
			state.add_note_once(&"leak-observation", "A leak contained", LEAK_NOTE)
			_play_effect(DRIP_SOUND)
			wick.react_to(LEAK_X, FLOOR_Y - 125.0)
			_start_dialogue(["Caught it. The drops are landing in the bucket now."])
		return
	if absf(x - ladder.position.x) <= 112.0:
		var ladder_aligned := absf(ladder.position.x - CASE_X) <= 80.0
		var can_climb: bool = bool(state.flags.get("stacks_ladder_locked", true)) \
			and (state.flags.get("stacks_ladder_ready_to_climb", false) or ladder_aligned)
		if can_climb:
			_begin_climb()
		else:
			_begin_ladder_push()
		return
	if absf(x - CASE_X) <= 105.0 and absf(ladder.position.x - CASE_X) > 80.0:
		_start_dialogue(["I can't reach that shelf from here. The ladder needs to be moved closer."])


func _begin_ladder_push() -> void:
	state.flags["stacks_ladder_locked"] = false
	kath.begin_pushing(ladder.position.x, LADDER_MIN_X, LADDER_MAX_X, 72.0)
	_play_effect(LADDER_SOUND)
	ui.show_hint("A / D OR ← / →  MOVE  ·  E  LOCK", 5.0)


func _end_ladder_push() -> void:
	ladder.position.x = kath.position.x + 72.0
	ladder.position.x = clampf(ladder.position.x, LADDER_MIN_X, LADDER_MAX_X)
	state.flags["stacks_ladder_x"] = ladder.position.x
	state.flags["stacks_ladder_locked"] = true
	state.flags["stacks_ladder_ready_to_climb"] = true
	kath.stop_pushing(ladder.position.x)
	_play_effect(LADDER_SOUND)


func _begin_climb() -> void:
	if not state.flags.get("stacks_ladder_locked", true):
		_start_dialogue(["The ladder is still rolling. I should lock its wheels before climbing."])
		return
	if absf(kath.position.x - ladder.position.x) > 112.0:
		kath.position.x = ladder.position.x - 72.0
	kath.begin_climbing(ladder.position.x, 294.0, FLOOR_Y)
	state.flags["stacks_ladder_ready_to_climb"] = false
	has_climbed_above_floor = false
	_play_effect(LADDER_SOUND)
	ui.show_hint("W / S OR ↑ / ↓  CLIMB  ·  E  OPEN CASE", 4.0)


func _can_open_case() -> bool:
	return kath.locomotion_mode == &"climb" \
		and absf(ladder.position.x - CASE_X) <= 80.0 \
		and absf(kath.position.x - CASE_X) <= 82.0 \
		and kath.position.y <= 398.0


func _interact_case() -> void:
	if not case_open:
		case_open = true
		state.flags["stacks_case_open"] = true
		case_sprite.frame = 1
		_play_effect(CASE_SOUND)
		wick.react_to(CASE_X + 80.0, kath.position.y - 165.0)
		_start_dialogue(["A box, tucked behind the atlas spines. No accession number.", "Wick... is that a page inside?"])
		return
	if state.flags.get("stacks_page_collected", false):
		_start_dialogue(["Just the empty box now. I should compare the page with my notebook."])
		return
	page_from_journal = false
	_play_effect(PAGE_SOUND)
	_set_mode(&"paper")
	ui.show_torn_page(false)


func _close_paper(collect: bool) -> void:
	ui.hide_modals()
	if collect and not state.flags.get("stacks_page_collected", false):
		state.flags["stacks_page_collected"] = true
		state.add_note_once(&"newton-note", "A torn page", NEWTON_NOTE)
		case_sprite.frame = 2
		_play_effect(PENCIL_SOUND)
		_set_mode(&"dialogue")
		if not state.flags.get("stacks_page_line_seen", false):
			state.flags["stacks_page_line_seen"] = true
			_start_dialogue(["This is my handwriting. I need to compare it with my notebook."])
		else:
			_set_mode(&"roam")
	else:
		_set_mode(&"roam")
	page_from_journal = false


func _return_to_journal() -> void:
	page_from_journal = false
	_set_mode(&"journal")
	_show_journal()


func _show_journal() -> void:
	ui.show_journal(state.notes, state.hall_checks_complete(), bool(state.flags.get("machine_baseline_recorded", false)), bool(state.flags.get("stacks_bucket_moved", false)), bool(state.flags.get("stacks_page_collected", false)))


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


func _close_dialogue(_completed: bool) -> void:
	_close_modal()


func _close_modal() -> void:
	ui.hide_modals()
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"


func _play_effect(stream: AudioStream) -> void:
	effects_player.stop()
	effects_player.stream = stream
	effects_player.play()


func ripple_setup() -> void:
	# Keep the ripples beneath the bucket so the catch remains legible at a glance.
	ripple.position = Vector2(LEAK_X, FLOOR_Y - 20.0)
	ripple.scale = Vector2(0.45, 0.45)
	ripple.modulate = Color(0.8, 0.87, 0.93, 0.58)
	ripple.visible = true
	ripple.play("default")


