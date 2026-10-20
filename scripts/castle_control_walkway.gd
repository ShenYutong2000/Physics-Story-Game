extends Node2D
## Fixed control tower: Kath observes Erin's return test and the on-site inversion.

const SERVICE_ROAD_SCENE := "res://scenes/service_road.tscn"
const INVERTED_ROOM_SCENE := "res://scenes/chapter1_inverted_room.tscn"
const FLOOR_Y := 755.0
const SOURCE_WING_POSE_ANGLE := deg_to_rad(12.0)
const MOTOR_AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-machine.wav")
const LEVER_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const STOP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/stop-switch.wav")

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var ui: CanvasLayer = $HallUI
@onready var return_exit: Node2D = $ReturnExit
@onready var erin_station: Node2D = $ErinStation
@onready var position_dial: Node2D = $PositionDial
@onready var return_console: Node2D = $ReturnConsole
@onready var lower_service_hatch: Node2D = $LowerServiceHatch
@onready var lower_service_hatch_art: Sprite2D = $LowerServiceHatchArt
@onready var erin: Node2D = $Erin
@onready var castle_wing_pivot: Node2D = $CastleWingPivot
@onready var dial_needle_pivot: Node2D = $DialNeedlePivot
@onready var state: Node = get_node("/root/PrologueState")
@onready var hotspots: Array[Node] = [return_exit, erin_station, position_dial, return_console, lower_service_hatch]

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_speakers: Array[StringName] = []
var dialogue_index := 0
var pending_dialogue_action: StringName = &""
var motor_player: AudioStreamPlayer
var effect_player: AudioStreamPlayer


func _ready() -> void:
	var spawn_tag: StringName = state.take_spawn_tag()
	_apply_pose_from_state()
	lower_service_hatch_art.visible = state.castle_pose == &"inverted" and bool(state.flags.get("control_inversion_complete", false))
	kath.floor_y = FLOOR_Y
	kath.floor_slope = 0.0
	kath.left_limit = 85.0
	kath.right_limit = 625.0
	kath.position = Vector2(575.0 if spawn_tag == &"from-inverted-room" else 430.0, FLOOR_Y)
	erin.visible = state.castle_pose != &"inverted"
	motor_player = AudioStreamPlayer.new()
	motor_player.stream = MOTOR_AMBIENCE
	motor_player.volume_db = -22.0
	add_child(motor_player)
	effect_player = AudioStreamPlayer.new()
	add_child(effect_player)
	if not state.flags.get("control_walkway_intro_seen", false):
		state.flags["control_walkway_intro_seen"] = true
		_start_dialogue([
			"The fixed walkway is still standing. The supported wing is tilted inside the ring.",
			"Erin is here. I should compare the position dial with what we can actually see."
		])
	elif spawn_tag == &"from-inverted-room":
		ui.show_hint("Back at the fixed tower. The lower hatch remains open.", 4.0)
	elif state.castle_pose == &"inverted":
		ui.show_hint("The old bridge no longer meets the wing. Check the lower service hatch.", 4.0)


func _exit_tree() -> void:
	if is_instance_valid(motor_player):
		motor_player.stop()
	if is_instance_valid(effect_player):
		effect_player.stop()


func _process(_delta: float) -> void:
	if mode != &"roam":
		ui.hide_prompt()
		return
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var action := "INSPECT"
	var prompt_y := 185.0
	if closest == return_exit:
		action = "RETURN"
		prompt_y = FLOOR_Y - 430.0
	elif closest == erin_station:
		action = "TALK"
		prompt_y = 300.0
	elif closest == return_console:
		action = "START" if _return_test_ready() else "CHECK"
		prompt_y = 260.0
	elif closest == lower_service_hatch:
		action = "ENTER"
		prompt_y = 300.0
	ui.show_prompt(closest.display_name, 830.0 if closest == lower_service_hatch else closest.approach_x, action, prompt_y)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		if mode == &"cutscene":
			return
		get_viewport().set_input_as_handled()
		if mode == &"roam":
			_set_mode(&"paused")
			ui.show_pause()
		elif mode == &"paper":
			_set_mode(&"journal")
			_show_journal()
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
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()
	elif mode == &"journal":
		if event.is_action_pressed("toggle_journal"):
			get_viewport().set_input_as_handled()
			_close_overlay()
		elif event.is_action_pressed("advance_dialogue") and state.has_note(&"newton-note"):
			get_viewport().set_input_as_handled()
			_set_mode(&"paper")
			ui.show_torn_page(true)
		elif event.is_action_pressed("move_up"):
			get_viewport().set_input_as_handled()
			ui.scroll_journal(-1)
		elif event.is_action_pressed("move_down"):
			get_viewport().set_input_as_handled()
			ui.scroll_journal(1)
	elif mode == &"paused" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_close_overlay()


func nearest_hotspot(feet_x: float) -> Node:
	var best: Node = null
	var best_distance := INF
	for hotspot in hotspots:
		if hotspot == erin_station and not erin.visible:
			continue
		if hotspot == lower_service_hatch and not lower_service_hatch_art.visible:
			continue
		if not hotspot.is_reachable(feet_x):
			continue
		var distance: float = hotspot.distance_from(feet_x)
		if distance < best_distance:
			best = hotspot
			best_distance = distance
	return best


func _return_test_ready() -> bool:
	return state.castle_pose == &"tilted" \
		and bool(state.flags.get("incident_complete", false)) \
		and bool(state.flags.get("control_erin_briefed", false)) \
		and bool(state.flags.get("control_dial_checked", false))


func _inspect(hotspot: Node) -> void:
	if hotspot == return_exit:
		_return_to_service_road()
	elif hotspot == erin_station:
		_start_dialogue(
			["That sketch is our maintenance basket. You drew it before the records went blank.",
			"Then we both knew this place?",
			"We did. I still can't remember what we meant to test."],
			[&"erin", &"kath", &"erin"],
			&"erin_briefed"
		)
	elif hotspot == position_dial:
		if state.castle_pose == &"inverted":
			_start_dialogue(["The pointer reached the far stop. The fixed walkway did not turn with the wing."])
		else:
			_start_dialogue(
				["The pointer marks the same tilt I can see in the ring.",
				"I'll watch both during the return test. A pointer alone cannot tell me what the whole wing is doing."],
				[],
				&"dial_checked"
			)
	elif hotspot == return_console:
		if state.castle_pose == &"inverted":
			_start_dialogue(["The return test stopped here. Erin is beyond the bridge; I need a safe way to reach her."])
		elif not _return_test_ready():
			_start_dialogue(["Before trying the controls, I need Erin's account and a reading of the position dial."])
		else:
			_start_dialogue(
				["I'll take the service stair to the inner lock. Watch the wing and the dial from here.",
				"I'll stay on the fixed walkway and call out if they disagree."],
				[&"erin", &"kath"],
				&"begin_return_test"
			)
	elif hotspot == lower_service_hatch and lower_service_hatch_art.visible:
		_set_mode(&"travel")
		ui.hide_modals()
		state.travel_to(INVERTED_ROOM_SCENE, &"from-control-walkway")


func _return_to_service_road() -> void:
	_set_mode(&"travel")
	ui.hide_modals()
	state.travel_to(SERVICE_ROAD_SCENE, &"from-control-walkway")


func _start_dialogue(lines: Array[String], speakers: Array[StringName] = [], completion_action: StringName = &"") -> void:
	dialogue_lines = lines
	dialogue_speakers = speakers
	dialogue_index = 0
	pending_dialogue_action = completion_action
	_set_mode(&"dialogue")
	_show_current_dialogue()


func _show_current_dialogue() -> void:
	var anchor := kath.global_position
	if dialogue_index < dialogue_speakers.size() and dialogue_speakers[dialogue_index] == &"erin":
		anchor = erin.global_position if erin.visible else Vector2(755, 475)
	ui.show_dialogue(dialogue_lines[dialogue_index], anchor)


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_show_current_dialogue()
	else:
		var action := pending_dialogue_action
		_close_overlay()
		_complete_dialogue_action(action)


func _complete_dialogue_action(action: StringName) -> void:
	match action:
		&"erin_briefed":
			state.flags["control_erin_briefed"] = true
			state.add_note_once(
				&"castle-basket-sketch",
				"A sketch Erin recognizes",
				"Erin recognized the maintenance basket in my torn page. Neither of us remembers what we once meant to test at the Castle."
			)
		&"dial_checked":
			state.flags["control_dial_checked"] = true
			state.add_note_once(
				&"castle-position-baseline",
				"Castle position before the test",
				"The position dial and the wing in the support ring both show a small tilt. I will compare them during the local return test."
			)
		&"begin_return_test":
			_begin_return_test()


func _apply_pose_from_state() -> void:
	# The source artwork is painted at 12 degrees. Only the wing rotates;
	# the support ring, fixed tower and walkway remain in place.
	castle_wing_pivot.rotation = state.castle_pose_angle_radians() - SOURCE_WING_POSE_ANGLE
	match state.castle_pose:
		&"upright", &"restored":
			dial_needle_pivot.rotation = deg_to_rad(-12.0)
		&"tilted":
			dial_needle_pivot.rotation = 0.0
		&"inverted":
			dial_needle_pivot.rotation = deg_to_rad(40.0)


func _begin_return_test() -> void:
	if not _return_test_ready() or state.flags.get("control_return_test_started", false):
		return
	state.flags["control_return_test_started"] = true
	_set_mode(&"cutscene")
	ui.hide_modals()
	ui.hide_prompt()
	ui.show_hint("Erin takes the service stair to the inner lock.", 2.5)
	erin.set_walking(true)
	var approach := create_tween()
	approach.tween_property(erin, "position", Vector2(485, FLOOR_Y), 0.6)
	approach.tween_property(erin, "position", Vector2(625, 535), 1.0)
	approach.parallel().tween_property(erin, "scale", Vector2(0.72, 0.72), 1.0)
	await approach.finished
	# The elevated bridge is painted into the fixed architecture. Keep Erin
	# behind its rail as she crosses to the rotating wing's inner doorway.
	erin.z_index = -11
	var crossing := create_tween().set_parallel(true)
	crossing.tween_property(erin, "position", Vector2(1260, 525), 1.5)
	crossing.tween_property(erin, "scale", Vector2(0.52, 0.52), 1.5)
	await crossing.finished
	erin.set_walking(false)
	erin.visible = false
	_play_effect(LEVER_SOUND)
	motor_player.play()
	ui.show_hint("The wing is moving back toward level.", 2.0)
	var return_motion := create_tween().set_parallel(true)
	return_motion.tween_property(castle_wing_pivot, "rotation", -SOURCE_WING_POSE_ANGLE, 1.5)
	return_motion.tween_property(dial_needle_pivot, "rotation", deg_to_rad(-12.0), 1.5)
	await return_motion.finished
	ui.show_hint("The pointer passed home. The wing did not stop.", 2.4)
	await get_tree().create_timer(0.45).timeout
	_play_effect(STOP_SOUND)
	wick.react_to(1530.0, 440.0)
	var run_on := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Continue in the same direction past level, ending at -180 degrees.
	# That is visually equivalent to the shared state's +180-degree pose.
	run_on.tween_property(castle_wing_pivot, "rotation", deg_to_rad(-180.0) - SOURCE_WING_POSE_ANGLE, 3.0)
	run_on.tween_property(dial_needle_pivot, "rotation", deg_to_rad(40.0), 3.0)
	await run_on.finished
	motor_player.stop()
	if not state.transition_castle_pose(&"inverted"):
		_set_mode(&"roam")
		return
	_apply_pose_from_state()
	lower_service_hatch_art.visible = true
	state.flags["control_inversion_complete"] = true
	state.add_note_once(
		&"castle-on-site-inversion",
		"The wing passed its stop",
		"During the return test, the wing moved toward level, passed the intended stop, and continued to the inverted position. The fixed tower stayed upright. Erin reached an inner maintenance ledge; the cause is not yet known."
	)
	_start_dialogue(
		["Erin? I saw the wing pass level and keep turning.",
		"I'm safe on an inner maintenance ledge, but the old bridge no longer meets this side.",
		"I'll look for another route. First, I need to see what is safe to stand on."],
		[&"kath", &"erin", &"kath"]
	)


func _play_effect(stream: AudioStream) -> void:
	effect_player.stop()
	effect_player.stream = stream
	effect_player.play()


func _show_journal() -> void:
	ui.show_journal(
		state.notes,
		state.hall_checks_complete(),
		bool(state.flags.get("machine_baseline_recorded", false)),
		bool(state.flags.get("stacks_bucket_moved", false)),
		bool(state.flags.get("stacks_page_collected", false)),
		bool(state.flags.get("room_notebook_compared", false)),
		bool(state.flags.get("incident_complete", false)),
		state.room_preparation_complete(),
		bool(state.flags.get("machine_incident_active", false)),
		bool(state.flags.get("service_gate_open", false)),
		bool(state.flags.get("service_road_end_reached", false))
	)


func _close_overlay() -> void:
	ui.hide_modals()
	pending_dialogue_action = &""
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"
