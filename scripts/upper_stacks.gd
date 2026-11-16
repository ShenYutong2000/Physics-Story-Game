extends StoryRoom
## Exploration, leak response, and the rolling ladder in the Upper Stacks.

const HALL_SCENE := "res://scenes/library_hall.tscn"
const ROOM_SCENE := "res://scenes/kath_room.tscn"
const AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-room.wav")
const DRIP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/water-drop.wav")
const CASE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/case-open.wav")
const LADDER_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/ladder-step.wav")
const PAGE_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/page-turn.wav")
const LEAK_NOTE := "Rain slips through a roof seam above the stacks. Moving a bucket beneath the falling water stopped it reaching the floor."
const NEWTON_NOTE := "A torn page reads F = ma. The measurements are crossed out and repeated. Beneath them is a faint, incomplete sketch of a hanging basket. At the bottom: ‘Next time at the castle, try again.’ The handwriting is Kath's."

const FLOOR_Y := 708.0
const LADDER_START_X := 1198.0
const LADDER_MIN_X := 800.0
const LADDER_MAX_X := 1430.0
const LADDER_PUSH_OFFSET := 72.0
const LADDER_REACH := 112.0
const LADDER_TOP_Y := 294.0
const CASE_X := 1012.0
const CASE_ALIGN := 80.0
const LEAK_X := 1410.0
const LEAK_REACH := 125.0
const RETURN_X := 500.0
const ROOM_DOOR_X := 100.0
const DROP_TOP_Y := 282.0
const DROP_CYCLE := 1.25

@onready var ladder: Sprite2D = $RollingLadder
@onready var case_sprite: AnimatedSprite2D = $WoodenCase/AnimatedSprite2D
@onready var bucket: Sprite2D = $Bucket
@onready var ripple: AnimatedSprite2D = $Ripple
@onready var rain_drop: Sprite2D = $RainDrop
@onready var far: Sprite2D = $Far
@onready var rain_streaks: Node2D = $RainStreaks

var drip_player: AudioStreamPlayer
var drip_timer := 0.0
var drop_elapsed := 0.0
var has_climbed_above_floor := false
var leak_inspected := false
var case_open := false


func _ready() -> void:
	var spawn_tag: StringName = state.take_spawn_tag()
	var spawn_x := RETURN_X
	if spawn_tag == &"from-upper-stacks":
		spawn_x = 1530.0
	elif spawn_tag == &"from-kath-room":
		spawn_x = ROOM_DOOR_X
	kath.position = Vector2(spawn_x, FLOOR_Y)
	_apply_archive_weather(far, rain_streaks, false)
	ladder.position = Vector2(float(state.flags.get("stacks_ladder_x", LADDER_START_X)), FLOOR_Y)
	case_sprite.frame = 2 if _flag("stacks_page_collected") else (1 if _flag("stacks_case_open") else 0)
	_place_bucket()
	case_open = _flag("stacks_case_open")
	leak_inspected = _flag("stacks_leak_inspected")
	_add_audio("UpperStacksAmbience", AMBIENCE, -16.0, true)
	drip_player = _add_audio("DripAudio", DRIP_SOUND, -11.0, true, false)
	if spawn_tag == &"from-hall" and not _flag("stacks_intro_seen"):
		state.flags["stacks_intro_seen"] = true
		_start_dialogue(["There. A roof seam above the shelves.", "I'll put the bucket where the drops are landing, then find a safe way to reach that top row."])


func _flag(key: String) -> bool:
	return bool(state.flags.get(key, false))


func _ladder_at_case() -> bool:
	return absf(ladder.position.x - CASE_X) <= CASE_ALIGN


func _ladder_can_climb() -> bool:
	return bool(state.flags.get("stacks_ladder_locked", true)) \
		and (_flag("stacks_ladder_ready_to_climb") or _ladder_at_case())


func _can_open_case() -> bool:
	return kath.locomotion_mode == &"climb" \
		and _ladder_at_case() \
		and absf(kath.position.x - CASE_X) <= 82.0 \
		and kath.position.y <= 398.0


func discovery_candidates() -> Array[Dictionary]:
	var case_marker := {"x": CASE_X, "position": Vector2(CASE_X, 300), "id": &"stacks-case"}
	var case_reachable := _ladder_at_case() and not _flag("stacks_page_collected")
	if kath.locomotion_mode == &"climb":
		return [case_marker] if case_reachable else []
	var items: Array[Dictionary] = [
		{"x": RETURN_X, "position": Vector2(RETURN_X, 485), "id": &"stacks-hall-exit"},
		{"x": LEAK_X, "position": Vector2(LEAK_X, 330), "id": &"stacks-leak"},
		{"x": ladder.position.x, "position": Vector2(ladder.position.x, 470), "id": &"stacks-ladder"},
	]
	if _flag("stacks_page_collected"):
		items.append({"x": ROOM_DOOR_X, "position": Vector2(ROOM_DOOR_X, 440), "id": &"stacks-room-exit"})
	if case_reachable:
		items.append(case_marker)
	return items


func _process(delta: float) -> void:
	_animate_leak(delta)
	if kath.locomotion_mode == &"push":
		ladder.position.x = clampf(kath.position.x + LADDER_PUSH_OFFSET, LADDER_MIN_X, LADDER_MAX_X)
		state.flags["stacks_ladder_x"] = ladder.position.x
	if kath.locomotion_mode == &"climb":
		if kath.position.y < FLOOR_Y - 5.0:
			has_climbed_above_floor = true
		if kath.position.y >= FLOOR_Y - 0.1 and (has_climbed_above_floor or Input.is_action_pressed("move_down")):
			kath.stop_climbing()
			has_climbed_above_floor = false
			_play_effect(LADDER_SOUND)
	_update_prompt()


## The bucket changes where the drops land, not the direction of the rain.
func _animate_leak(delta: float) -> void:
	drop_elapsed = fposmod(drop_elapsed + delta, DROP_CYCLE)
	var catch_y := FLOOR_Y - 88.0 if _flag("stacks_bucket_moved") else FLOOR_Y - 20.0
	rain_drop.visible = true
	rain_drop.position = Vector2(LEAK_X, lerpf(DROP_TOP_Y, catch_y, drop_elapsed / DROP_CYCLE))
	rain_drop.modulate.a = 1.0 if drop_elapsed < 1.12 else 1.0 - (drop_elapsed - 1.12) / 0.13
	drip_timer -= delta
	if drip_timer <= 0.0 and not drip_player.playing:
		drip_player.volume_db = -18.0 if _flag("stacks_bucket_moved") else -11.0
		drip_player.play()
		drip_timer = 1.7


func _update_prompt() -> void:
	if mode != &"roam" or kath.locomotion_mode == &"push":
		ui.hide_prompt()
		return
	var feet_x := kath.position.x
	if kath.locomotion_mode == &"climb":
		if _can_open_case():
			ui.show_prompt("Wooden case", CASE_X, "OPEN CASE", kath.position.y - 120.0)
		else:
			ui.hide_prompt()
	elif absf(feet_x - ROOM_DOOR_X) <= 92.0 and _flag("stacks_page_collected"):
		ui.show_prompt("Kath's Room", ROOM_DOOR_X, "ENTER", 255.0)
	elif absf(feet_x - RETURN_X) <= LADDER_REACH:
		ui.show_prompt("Stairway to Hall", RETURN_X, "RETURN", 260.0)
	elif absf(feet_x - LEAK_X) <= LEAK_REACH:
		var leak_action := "CHECK CATCH" if _flag("stacks_bucket_moved") else ("MOVE BUCKET" if leak_inspected else "INSPECT")
		ui.show_prompt("Roof seam", LEAK_X, leak_action, 238.0)
	elif absf(feet_x - ladder.position.x) <= LADDER_REACH:
		ui.show_prompt("Rolling ladder", ladder.position.x, "CLIMB" if _ladder_can_climb() else "PUSH LADDER", 440.0)
	elif absf(feet_x - CASE_X) <= 105.0 and not _ladder_at_case():
		ui.show_prompt("High shelf", CASE_X, "LADDER TOO FAR", 258.0)
	else:
		ui.hide_prompt()


func _room_input(event: InputEvent) -> bool:
	# The page picked up from the case is collected on Enter; Esc puts it back.
	if mode == &"paper" and not page_from_journal:
		if event.is_action_pressed("advance_dialogue"):
			_close_paper(true)
			return true
		if event.is_action_pressed("ui_cancel"):
			_close_paper(false)
			return true
	return false


func _interact() -> void:
	var x := kath.position.x
	if kath.locomotion_mode == &"climb":
		if _can_open_case():
			_interact_case()
	elif kath.locomotion_mode == &"push":
		_end_ladder_push()
	elif x <= 195.0 and _flag("stacks_page_collected"):
		state.travel_to(ROOM_SCENE, &"from-upper-stacks")
	elif absf(x - RETURN_X) <= LADDER_REACH:
		state.travel_to(HALL_SCENE, &"from-upper-stacks")
	elif absf(x - LEAK_X) <= LEAK_REACH:
		_inspect_leak()
	elif absf(x - ladder.position.x) <= LADDER_REACH:
		if _ladder_can_climb():
			_begin_climb()
		else:
			_begin_ladder_push()
	elif absf(x - CASE_X) <= 105.0 and not _ladder_at_case():
		_start_dialogue(["I can't reach that shelf from here. The ladder needs to be moved closer."])


func _inspect_leak() -> void:
	if _flag("stacks_bucket_moved"):
		_start_dialogue(["The seam is still leaking. The drops now strike the bucket instead of the boards; the floor is no longer being soaked."])
	elif not leak_inspected:
		leak_inspected = true
		state.flags["stacks_leak_inspected"] = true
		wick.react_to(LEAK_X - 20.0, 342.0)
		_start_dialogue(["The water is falling in a narrow line from that split in the roof.", "The bucket is close enough to slide beneath it."])
	else:
		state.flags["stacks_bucket_moved"] = true
		_place_bucket()
		state.add_note_once(&"leak-observation", "A leak contained", LEAK_NOTE)
		_play_effect(DRIP_SOUND)
		wick.react_to(LEAK_X, FLOOR_Y - 125.0)
		_start_dialogue(["Caught it. The drops are landing in the bucket now."])


func _begin_ladder_push() -> void:
	state.flags["stacks_ladder_locked"] = false
	kath.begin_pushing(ladder.position.x, LADDER_MIN_X, LADDER_MAX_X, LADDER_PUSH_OFFSET)
	_play_effect(LADDER_SOUND)
	ui.show_hint("A / D OR ← / →  MOVE  ·  E  LOCK", 5.0)


func _end_ladder_push() -> void:
	ladder.position.x = clampf(kath.position.x + LADDER_PUSH_OFFSET, LADDER_MIN_X, LADDER_MAX_X)
	state.flags["stacks_ladder_x"] = ladder.position.x
	state.flags["stacks_ladder_locked"] = true
	state.flags["stacks_ladder_ready_to_climb"] = true
	kath.stop_pushing(ladder.position.x)
	_play_effect(LADDER_SOUND)


func _begin_climb() -> void:
	if not state.flags.get("stacks_ladder_locked", true):
		_start_dialogue(["The ladder is still rolling. I should lock its wheels before climbing."])
		return
	if absf(kath.position.x - ladder.position.x) > LADDER_REACH:
		kath.position.x = ladder.position.x - LADDER_PUSH_OFFSET
	kath.begin_climbing(ladder.position.x, LADDER_TOP_Y, FLOOR_Y)
	state.flags["stacks_ladder_ready_to_climb"] = false
	has_climbed_above_floor = false
	_play_effect(LADDER_SOUND)
	ui.show_hint("W / S OR ↑ / ↓  CLIMB  ·  E  OPEN CASE", 4.0)


func _interact_case() -> void:
	if not case_open:
		case_open = true
		state.flags["stacks_case_open"] = true
		case_sprite.frame = 1
		_play_effect(CASE_SOUND)
		wick.react_to(CASE_X + 80.0, kath.position.y - 165.0)
		_start_dialogue(["A box, tucked behind the atlas spines. No accession number.", "Wick... is that a page inside?"])
	elif _flag("stacks_page_collected"):
		_start_dialogue(["Just the empty box now. I should compare the page with my notebook."])
	else:
		page_from_journal = false
		_play_effect(PAGE_SOUND)
		_set_mode(&"paper")
		ui.show_torn_page(false)


func _close_paper(collect: bool) -> void:
	ui.hide_modals()
	page_from_journal = false
	_set_mode(&"roam")
	if not collect or _flag("stacks_page_collected"):
		return
	state.flags["stacks_page_collected"] = true
	state.add_note_once(&"newton-note", "A torn page", NEWTON_NOTE)
	case_sprite.frame = 2
	_play_effect(PENCIL_SOUND)
	if not _flag("stacks_page_line_seen"):
		state.flags["stacks_page_line_seen"] = true
		_start_dialogue(["This is my handwriting. I need to compare it with my notebook."])


## The splash shifts from the floor to the bucket, on return visits too.
func _place_bucket() -> void:
	var caught := _flag("stacks_bucket_moved")
	bucket.position = Vector2(LEAK_X if caught else 900.0, FLOOR_Y - 48.0)
	ripple.position = Vector2(LEAK_X, FLOOR_Y - 86.0 if caught else FLOOR_Y - 20.0)
	ripple.scale = Vector2(0.45, 0.45)
	ripple.modulate = Color(0.8, 0.87, 0.93, 0.58)
	ripple.visible = true
	ripple.play("default")
