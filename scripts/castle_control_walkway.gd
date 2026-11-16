extends StoryRoom
## Fixed control tower: Kath observes Erin's return test and the on-site inversion.

const SERVICE_ROAD_SCENE := "res://scenes/service_road.tscn"
const INVERTED_ROOM_SCENE := "res://scenes/chapter1_inverted_room.tscn"
const FLOOR_Y := 755.0
## The wing art is painted at the tilted pose; only the wing node rotates.
const SOURCE_WING_POSE_ANGLE := deg_to_rad(12.0)
const MOTOR_AMBIENCE: AudioStream = preload("res://prologue-asset-pack-v1/audio/amb-machine.wav")
const LEVER_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const STOP_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/stop-switch.wav")
const LAMP_DARK := Color(70 / 255.0, 88 / 255.0, 102 / 255.0)  # #465866
const LAMP_LIT := Color(233 / 255.0, 173 / 255.0, 97 / 255.0)  # #e9ad61
const LAMP_RUNNING := Color(255 / 255.0, 208 / 255.0, 120 / 255.0)  # #ffd078
const LAMP_TRIPPED := Color(118 / 255.0, 52 / 255.0, 58 / 255.0)  # #76343a
const RING_LAMP_IDLE := Color(239 / 255.0, 170 / 255.0, 83 / 255.0)  # #efaa53
const ERIN_OFFSTAGE := Vector2(755, 475)

@onready var return_exit: Node2D = $ReturnExit
@onready var erin_station: Node2D = $ErinStation
@onready var position_dial: Node2D = $PositionDial
@onready var return_console: Node2D = $ReturnConsole
@onready var lower_service_hatch: Node2D = $LowerServiceHatch
@onready var lower_service_hatch_art: Sprite2D = $LowerServiceHatchArt
@onready var erin: Node2D = $Erin
@onready var castle_wing_pivot: Node2D = $CastleWingPivot
@onready var dial_needle_pivot: Node2D = $DialNeedlePivot
@onready var archive_line_lamp: Polygon2D = $ArchiveLineLamp
@onready var ring_drive_lamp: Polygon2D = $RingDriveLamp

## Who says each line of the current dialogue (&"erin" or &"kath").
var dialogue_speakers: Array[StringName] = []
var motor_player: AudioStreamPlayer


func _ready() -> void:
	hotspots = [return_exit, erin_station, position_dial, return_console, lower_service_hatch]
	var spawn_tag: StringName = state.take_spawn_tag()
	_apply_pose_from_state()
	lower_service_hatch_art.visible = state.castle_pose == &"inverted" and bool(state.flags.get("control_inversion_complete", false))
	kath.floor_y = FLOOR_Y
	kath.floor_slope = 0.0
	kath.left_limit = 85.0
	kath.right_limit = 625.0
	kath.position = Vector2(575.0 if spawn_tag == &"from-inverted-room" else 430.0, FLOOR_Y)
	erin.visible = state.castle_pose != &"inverted"
	motor_player = _add_audio("RingMotor", MOTOR_AMBIENCE, -22.0, true, false)
	if not state.flags.get("control_walkway_intro_seen", false):
		state.flags["control_walkway_intro_seen"] = true
		_start_dialogue([
			"The fixed walkway is still standing. The supported wing is tilted inside the ring.",
			"The Archive-line lamp is dark, but the ring-drive lamp is still lit. Erin is here; I should compare the dial with the wing."
		])
	elif spawn_tag == &"from-inverted-room":
		ui.show_hint("Back at the fixed tower. The lower hatch remains open.", 4.0)
	elif state.castle_pose == &"inverted":
		ui.show_hint("The old bridge no longer meets the wing. Check the lower service hatch.", 4.0)


func _process(_delta: float) -> void:
	var closest := nearest_hotspot(kath.position.x) if mode == &"roam" else null
	if closest == null:
		ui.hide_prompt()
		return
	var action := "INSPECT"
	var prompt_y := 185.0
	var prompt_x: float = closest.approach_x
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
		prompt_x = 830.0
	ui.show_prompt(closest.display_name, prompt_x, action, prompt_y)


func _is_hotspot_available(hotspot: Node) -> bool:
	if hotspot == erin_station:
		return erin.visible
	if hotspot == lower_service_hatch:
		return lower_service_hatch_art.visible
	return true


func _return_test_ready() -> bool:
	return state.castle_pose == &"tilted" \
		and bool(state.flags.get("incident_complete", false)) \
		and bool(state.flags.get("control_erin_briefed", false)) \
		and bool(state.flags.get("control_dial_checked", false))


func _inspect(hotspot: Node) -> void:
	if hotspot == return_exit:
		_travel(SERVICE_ROAD_SCENE, &"from-control-walkway")
	elif hotspot == erin_station:
		_converse(
			["That sketch is our maintenance basket. You drew it before the records went blank.",
			"Then we both knew this place?",
			"We did. I still can't remember what we meant to test."],
			[&"erin", &"kath", &"erin"],
			&"erin_briefed"
		)
	elif hotspot == position_dial:
		if state.castle_pose == &"inverted":
			_start_dialogue(["The pointer reached the inverted catch. The fixed walkway did not turn with the wing.", "The ring drive fell silent at the catch, but its feed is still connected. We need the isolator in the fixed core."])
		else:
			_start_dialogue(
				["The pointer marks the same tilt I can see in the ring.",
				"The Archive-line lamp is dark. The Castle's ring-drive lamp is lit. Stopping one has not isolated the other.",
				"I'll watch both dial and wing during the return test. A pointer alone cannot tell me what the whole wing is doing."],
				&"dial_checked"
			)
	elif hotspot == return_console:
		if state.castle_pose == &"inverted":
			_start_dialogue(["The return test stopped here. Erin is beyond the bridge; I need a safe way to reach her."])
		elif not _return_test_ready():
			_start_dialogue(["Before trying the controls, I need Erin's account and a reading of the position dial."])
		else:
			_converse(
				["The Archive line is off; this brief return test uses the Castle's own ring drive. Its home contact should stop the motor. The independent isolator is inside the fixed core.",
				"I'll stay on the fixed walkway and compare the dial, lamps and wing. Keep the test slow."],
				[&"erin", &"kath"],
				&"begin_return_test"
			)
	elif hotspot == lower_service_hatch:
		_travel(INVERTED_ROOM_SCENE, &"from-control-walkway")


# --- Dialogue with two speakers -----------------------------------------------

func _converse(lines: Array[String], speakers: Array[StringName], completion_action: StringName = &"") -> void:
	dialogue_speakers = speakers
	_start_dialogue(lines, completion_action)


func _show_dialogue_line() -> void:
	var anchor := kath.global_position
	if dialogue_index < dialogue_speakers.size() and dialogue_speakers[dialogue_index] == &"erin":
		anchor = erin.global_position if erin.visible else ERIN_OFFSTAGE
	ui.show_dialogue(dialogue_lines[dialogue_index], anchor)


func _close_overlay() -> void:
	dialogue_speakers = []
	super()


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


# --- Castle pose ----------------------------------------------------------------

func _apply_pose_from_state() -> void:
	# Only the wing rotates; the support ring, fixed tower and walkway stay put.
	castle_wing_pivot.rotation = state.castle_pose_angle_radians() - SOURCE_WING_POSE_ANGLE
	archive_line_lamp.color = LAMP_DARK if state.flags.get("incident_drive_stopped", false) else LAMP_LIT
	ring_drive_lamp.color = LAMP_TRIPPED if state.castle_pose == &"inverted" else RING_LAMP_IDLE
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
	ring_drive_lamp.color = LAMP_RUNNING
	ui.show_hint("CASTLE RING DRIVE ON · WING MOVING TOWARD HOME", 2.0)
	var return_motion := create_tween().set_parallel(true)
	return_motion.tween_property(castle_wing_pivot, "rotation", -SOURCE_WING_POSE_ANGLE, 1.5)
	return_motion.tween_property(dial_needle_pivot, "rotation", deg_to_rad(-12.0), 1.5)
	await return_motion.finished
	ui.show_hint("HOME SIGNAL DARK · RING DRIVE STILL ON", 2.4)
	await get_tree().create_timer(0.45).timeout
	_play_effect(STOP_SOUND)
	ui.show_hint("Kath releases the test lever. The ring-drive lamp stays lit.", 2.8)
	wick.react_to(1530.0, 440.0)
	var run_on := create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# Continue in the same direction past level, ending at -180 degrees.
	# That is visually equivalent to the shared state's +180-degree pose.
	run_on.tween_property(castle_wing_pivot, "rotation", deg_to_rad(-180.0) - SOURCE_WING_POSE_ANGLE, 3.0)
	run_on.tween_property(dial_needle_pivot, "rotation", deg_to_rad(40.0), 3.0)
	await run_on.finished
	motor_player.stop()
	ring_drive_lamp.color = LAMP_TRIPPED
	if not state.transition_castle_pose(&"inverted"):
		_set_mode(&"roam")
		return
	_apply_pose_from_state()
	lower_service_hatch_art.visible = true
	state.flags["control_inversion_complete"] = true
	state.flags["castle_overload_tripped"] = true
	state.add_note_once(
		&"castle-on-site-inversion",
		"The wing passed its stop",
		"The Archive feed was dark while the Castle ring drive ran. On the return test, the wing passed home with its stop lamp dark. Erin released the selector, but the motor kept running until the separate inverted catch held the wing; then it fell silent. The fixed tower stayed upright. The failed home stop still needs tracing."
	)
	_converse(
		["Erin? I saw the wing pass level and keep turning.",
		"I'm safe on an inner maintenance ledge, but the old bridge no longer meets this side.",
		"I'll look for another route. First, I need to see what is safe to stand on."],
		[&"kath", &"erin", &"kath"]
	)
