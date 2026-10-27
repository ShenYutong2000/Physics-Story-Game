extends Node2D
## Two rescue preparations: deliver Erin's tools, then prove the passenger rope with an empty basket.

const INVERTED_ROOM_SCENE := "res://scenes/chapter1_inverted_room.tscn"
const FLOOR_Y := 790.0
const BASKET_X := 1100.0
const BASKET_LOW_Y := 703.0
const BASKET_HIGH_Y := 358.0
const WINCH_SPEED := 0.19
const EMPTY_TEST_LIMIT := 0.28
const EMPTY_TEST_MIN_LIFT := 0.20
const CLICK_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")

@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var erin: Node2D = $ErinOnLedge
@onready var ui: CanvasLayer = $HallUI
@onready var return_aperture: Node2D = $ReturnAperture
@onready var speaking_tube: Node2D = $SpeakingTube
@onready var rig_inspection: Node2D = $RigInspection
@onready var tool_chest: Node2D = $ToolChest
@onready var winch_console: Node2D = $WinchConsole
@onready var long_rope_cabinet: Node2D = $LongRopeCabinet
@onready var lower_dock_latch: Node2D = $LowerDockLatch
@onready var top_anchor_survey: Node2D = $TopAnchorSurvey
@onready var rope_coil: Line2D = $RopeCoil
@onready var lower_dock_clamp: Polygon2D = $LowerDockClamp
@onready var pilot_guide: Line2D = $PilotGuide
@onready var moving_pulley: Sprite2D = $MovingPulley
@onready var pulley_cover: Polygon2D = $PulleyCover
@onready var rope_shadow: Line2D = $RopeShadow
@onready var rope_core: Line2D = $RopeCore
@onready var rope_mark_near: Line2D = $RopeMarkNear
@onready var rope_mark_far: Line2D = $RopeMarkFar
@onready var basket_rig: Node2D = $BasketRig
@onready var basket_tools: Sprite2D = $BasketRig/ToolCrate
@onready var platform_tools: Sprite2D = $PlatformToolCrate
@onready var transfer_tools: Sprite2D = $TransferCrate
@onready var loading_spur: Sprite2D = $LoadingSpur
@onready var receiving_rail: Sprite2D = $ReceivingRail
@onready var receiving_rail_open: Sprite2D = $ReceivingRailOpen
@onready var bent_rail: Line2D = $BentRailBar
@onready var open_rail: Line2D = $OpenRailStubs
@onready var load_indicator: Sprite2D = $LoadIndicator
@onready var brake_lever: Sprite2D = $BrakeLever
@onready var state: Node = get_node("/root/PrologueState")
@onready var hotspots: Array[Node] = [return_aperture, winch_console, rig_inspection, tool_chest, speaking_tube, long_rope_cabinet, lower_dock_latch, top_anchor_survey]

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var dialogue_speaker := Vector2.ZERO
var dialogue_beside_erin := false
var pending_dialogue_action: StringName = &""
var basket_progress := 0.0
var winch_motion_direction := 0.0
var rigging_step := 0
var sound_player: AudioStreamPlayer


func _ready() -> void:
	var spawn_tag: StringName = state.take_spawn_tag()
	ui.hint.position = Vector2(36, 45)
	ui.hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kath.floor_y = FLOOR_Y
	kath.left_limit = 90.0
	kath.right_limit = 815.0
	kath.position = Vector2(300.0, FLOOR_Y)
	basket_progress = clampf(float(state.flags.get("shaft_basket_progress", 0.0)), 0.0, 1.0)
	sound_player = AudioStreamPlayer.new()
	sound_player.stream = CLICK_SOUND
	sound_player.volume_db = -14.0
	add_child(sound_player)
	_update_rig_visuals()
	if spawn_tag == &"from-inverted-room" and not state.flags.get("shaft_intro_seen", false):
		state.flags["shaft_intro_seen"] = true
		_start_dialogue(["This fixed platform does not turn with the wing. Erin is stranded across the shaft; I should check the hoist and ask what she needs."])
	elif state.flags.get("shaft_empty_test_complete", false):
		ui.show_hint("The empty passenger rig held. Erin still needs a load check before boarding.", 5.0)
	elif state.flags.get("shaft_passenger_rethread_complete", false):
		ui.show_hint("Release the lower dock, then make a short empty-basket lift.", 5.0)
	elif state.flags.get("shaft_tool_trip_complete", false):
		ui.show_hint("Check the basket wheel, top anchor and rope cabinet before anyone rides.", 5.0)
	elif state.flags.get("shaft_rail_removed", false):
		ui.show_hint("Erin is clear. Lower the empty basket with the hand winch.", 5.0)
	elif state.flags.get("shaft_tools_loaded", false):
		ui.show_hint("The tool chest is secured. Operate the hand winch.", 5.0)
	elif state.flags.get("shaft_tool_goal", false):
		ui.show_hint("Load Erin's tools from the safe platform.", 5.0)


func _process(delta: float) -> void:
	if mode == &"winch":
		_process_winch(delta)
		ui.hide_prompt()
		return
	if mode != &"roam":
		ui.hide_prompt()
		return
	var closest: Node = nearest_hotspot(kath.position.x)
	if closest == null:
		ui.hide_prompt()
		return
	var action := "INSPECT"
	if closest == return_aperture:
		action = "RETURN"
	elif closest == speaking_tube:
		action = "CALL"
	elif closest == tool_chest and state.flags.get("shaft_tool_goal", false) and not state.flags.get("shaft_tools_loaded", false):
		action = "LOAD"
	elif closest == lower_dock_latch:
		if state.flags.get("shaft_empty_test_complete", false):
			action = "CHECK"
		elif state.flags.get("shaft_lower_dock_locked", false):
			action = "RELEASE" if state.flags.get("shaft_passenger_rethread_complete", false) else "CHECK"
		else:
			action = "LOCK"
	elif closest == long_rope_cabinet and not state.flags.get("shaft_long_rope_taken", false):
		action = "TAKE"
	elif closest == rig_inspection and state.flags.get("shaft_tool_trip_complete", false) and state.flags.get("shaft_passenger_rig_inspected", false) and state.flags.get("shaft_lower_dock_locked", false) and state.flags.get("shaft_long_rope_taken", false) and state.flags.get("shaft_top_anchor_inspected", false) and not state.flags.get("shaft_passenger_rethread_complete", false):
		action = "RETHREAD"
	elif closest == winch_console and state.flags.get("shaft_tools_loaded", false):
		action = "CHECK" if state.flags.get("shaft_empty_test_complete", false) or (state.flags.get("shaft_tool_trip_complete", false) and (not state.flags.get("shaft_passenger_rethread_complete", false) or state.flags.get("shaft_lower_dock_locked", false))) else "OPERATE"
	ui.show_prompt(closest.display_name, closest.approach_x, action, 430.0)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if mode == &"loading":
			return
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
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()
	elif mode == &"rigging" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_advance_rigging()
	elif mode == &"winch" and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if basket_progress >= 0.995 and not state.flags.get("shaft_rail_removed", false):
			erin.set_repairing(true)
			_start_dialogue([
				"Erin catches the tool chest and braces the basket against the docking catch.",
				"She loosens the bent rail and clears the entrance. I can now lower the empty basket."
			], &"clear_rail", erin.global_position)
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
		if hotspot in [long_rope_cabinet, lower_dock_latch, top_anchor_survey] and not state.flags.get("shaft_tool_trip_complete", false):
			continue
		if hotspot == tool_chest and state.flags.get("shaft_tool_trip_complete", false):
			continue
		if not hotspot.is_reachable(feet_x):
			continue
		var distance: float = hotspot.distance_from(feet_x)
		if distance < best_distance:
			best = hotspot
			best_distance = distance
	return best


func _inspect(hotspot: Node) -> void:
	if hotspot == return_aperture:
		_set_mode(&"travel")
		ui.hide_modals()
		state.travel_to(INVERTED_ROOM_SCENE, &"from-maintenance-shaft")
	elif hotspot == speaking_tube:
		wick.react_to(1420.0, 250.0)
		if state.flags.get("shaft_empty_test_complete", false):
			_start_dialogue(["Erin: I saw both rope runs stay seated. Before I step in, we must check the load with someone aboard."], &"", erin.global_position)
		elif state.flags.get("shaft_passenger_rethread_complete", false):
			_start_dialogue(["Erin: The top latch is closed and the rope sits in both wheels. Test it empty before I board."], &"", erin.global_position)
		elif state.flags.get("shaft_tool_trip_complete", false):
			_start_dialogue(["Erin: I can see the top anchor from here. Lock the empty basket below before changing its rope."], &"", erin.global_position)
		elif state.flags.get("shaft_rail_removed", false):
			_start_dialogue(["Erin: The entrance is clear. Wait until the basket is back before checking its ropes."], &"", erin.global_position)
		else:
			_start_dialogue([
				"Erin: The rail beside my landing is bent across the basket entrance.",
				"I can unfasten it if you send up the small tool chest. I cannot reach your platform from here."
			], &"contact_erin" if not state.flags.get("shaft_erin_contacted", false) else &"", erin.global_position)
	elif hotspot == rig_inspection:
		if state.flags.get("shaft_passenger_rethread_complete", false):
			_start_dialogue(["The long rope runs from the top anchor, under the basket wheel, over the fixed wheel and back to the winch. Two strands now hold the empty basket."])
		elif state.flags.get("shaft_tool_trip_complete", false):
			if not state.flags.get("shaft_passenger_rig_inspected", false):
				_start_dialogue([
					"The second sketch shows another wheel already bolted above the basket, under a metal cover.",
					"A thin pilot line crosses that wheel and the top anchor. I can pull a longer rope along it from this platform."
				], &"inspect_passenger_rig")
			elif not state.flags.get("shaft_lower_dock_locked", false):
				_start_dialogue(["I cannot release the old basket eye while its rope is taking the weight. Lock the empty basket to the lower dock first."])
			elif not state.flags.get("shaft_long_rope_taken", false):
				_start_dialogue(["The basket is supported by the lower dock. I still need the long rope from the cabinet."])
			elif not state.flags.get("shaft_top_anchor_inspected", false):
				_start_dialogue(["I should check the top anchor from the viewing mark before pulling the long rope through."])
			else:
				_start_rigging()
		else:
			_start_dialogue([
			"The basket matches the unfinished sketch on my torn page. Its cable passes over one fixed pulley to this hand winch.",
			"The automatic drive is still. The crank moves freely, and the empty basket rests by the loading spur."
			], &"inspect_rig" if not state.flags.get("shaft_rig_inspected", false) else &"")
	elif hotspot == long_rope_cabinet:
		if state.flags.get("shaft_long_rope_taken", false):
			_start_dialogue(["The long rope is beside the winch, ready for the guide line."])
		else:
			_start_dialogue(["A coiled maintenance rope is stored here. The far pulley is already on the basket; I can draw this rope through with the pilot line."], &"take_long_rope")
	elif hotspot == top_anchor_survey:
		wick.react_to(1160.0, 94.0)
		_start_dialogue(["From this viewing mark, I can see the separate top anchor and its pull-operated latch. Erin can check the wheel and latch from her ledge."], &"inspect_top_anchor" if not state.flags.get("shaft_top_anchor_inspected", false) else &"")
	elif hotspot == lower_dock_latch:
		if state.flags.get("shaft_empty_test_complete", false):
			_start_dialogue(["The empty basket is locked at the lower berth. Erin cannot board until I check a person's load."])
		elif not state.flags.get("shaft_lower_dock_locked", false):
			if basket_progress > 0.005:
				_start_dialogue(["The dock latch cannot catch a raised basket. I need to lower it first."])
			else:
				_start_dialogue(["This floor-operated linkage closes a clamp across the basket's lower frame. It will carry the weight while I change the rope."], &"lock_lower_dock")
		elif not state.flags.get("shaft_passenger_rethread_complete", false):
			_start_dialogue(["The clamp is carrying the empty basket. I should leave it locked until the new rope is secured."])
		else:
			_start_dialogue(["The new rope and top latch are secured. I can release the lower clamp for a short empty test."], &"release_lower_dock")
	elif hotspot == tool_chest:
		if not state.flags.get("shaft_tool_goal", false):
			_start_dialogue(["A small chest of spanners and cutters sits by the loading tray. I should ask Erin what she needs first."])
		elif not state.flags.get("shaft_tools_loaded", false):
			if basket_progress > 0.01:
				_start_dialogue(["The tray cannot reach a moving basket. I need to lower it into the loading berth."])
			else:
				_start_dialogue([
					"The tray extends from the safe platform into the empty basket. I can send the chest across without stepping over the edge.",
					"I'll secure the chest before I turn the winch."
				], &"load_tools")
		else:
			_start_dialogue(["The tool chest has already crossed into the basket."])
	elif hotspot == winch_console:
		if not state.flags.get("shaft_rig_inspected", false):
			_start_dialogue(["I should trace the cable and check what the crank moves before operating it."])
		elif not state.flags.get("shaft_tools_loaded", false):
			_start_dialogue(["The basket is still empty. Erin needs the tools first."])
		elif state.flags.get("shaft_rail_removed", false) and basket_progress <= 0.005 and not state.flags.get("shaft_tool_trip_complete", false):
			_start_dialogue([
				"The empty basket is back at the lower berth. The railing no longer blocks Erin.",
				"This single cable carried the tools, but I have not checked it for a person. The other pulley in my sketch may matter."
			], &"finish_tool_trip")
		elif state.flags.get("shaft_empty_test_complete", false):
			_start_dialogue(["The empty test held. Before Erin rides, I need a separate load check."])
		elif state.flags.get("shaft_passenger_rethread_complete", false) and state.flags.get("shaft_lower_dock_locked", false):
			_start_dialogue(["The lower clamp is still holding the basket. Release it at the dock linkage before the empty test."])
		elif state.flags.get("shaft_passenger_rethread_complete", false):
			_set_mode(&"winch")
			ui.show_shaft_winch(basket_progress, true, true)
		elif state.flags.get("shaft_tool_trip_complete", false) and basket_progress <= 0.005:
			_start_dialogue(["The empty basket is secured below. Before Erin can ride, I need to check the second pulley and its rope."])
		else:
			_set_mode(&"winch")
			ui.show_shaft_winch(basket_progress, state.flags.get("shaft_rail_removed", false))


func _process_winch(delta: float) -> void:
	var passenger_test: bool = state.flags.get("shaft_passenger_rethread_complete", false)
	var direction := 0.0
	if Input.is_action_pressed("move_up") and (passenger_test or not state.flags.get("shaft_rail_removed", false)):
		direction = 1.0
	elif Input.is_action_pressed("move_down"):
		direction = -1.0
	if passenger_test and direction == 0.0 and winch_motion_direction > 0.0 and basket_progress >= EMPTY_TEST_MIN_LIFT:
		state.flags["shaft_empty_test_held"] = true
		ui.show_hint("The brake holds. Now lower the empty basket to its berth.", 3.0)
	if direction != winch_motion_direction:
		brake_lever.rotation = -0.22 if direction != 0.0 else 0.0
		if direction != 0.0:
			sound_player.play()
		winch_motion_direction = direction
	if direction != 0.0:
		var speed := WINCH_SPEED * (0.5 if passenger_test else 1.0)
		basket_progress = clampf(basket_progress + direction * speed * delta, 0.0, EMPTY_TEST_LIMIT if passenger_test else 1.0)
		state.flags["shaft_basket_progress"] = basket_progress
		if passenger_test:
			state.flags["shaft_empty_test_peak"] = maxf(float(state.flags.get("shaft_empty_test_peak", 0.0)), basket_progress)
		_update_rig_visuals()
	ui.update_shaft_winch(basket_progress, state.flags.get("shaft_rail_removed", false), passenger_test)
	if passenger_test and direction < 0.0 and basket_progress <= 0.005 and state.flags.get("shaft_empty_test_held", false) and not state.flags.get("shaft_empty_test_complete", false):
		state.flags["shaft_lower_dock_locked"] = true
		state.flags["shaft_empty_test_complete"] = true
		state.add_note_once(&"shaft-empty-passenger-test", "Empty passenger test", "The new rope stayed in both wheels during a short empty lift and return. Two strands supported the basket; the winch took in more rope for the same rise. A person's load remains untested. Less force. More rope.")
		_update_rig_visuals()
		_start_dialogue(["The brake held, and the empty basket returned to its berth. Less force. More rope.", "That test did not carry Erin. I still need to check what changes when someone boards."])


func _update_rig_visuals() -> void:
	basket_rig.position = Vector2(BASKET_X, lerpf(BASKET_LOW_Y, BASKET_HIGH_Y, basket_progress))
	var rethreaded: bool = state.flags.get("shaft_passenger_rethread_complete", false)
	var trip_complete: bool = state.flags.get("shaft_tool_trip_complete", false)
	var basket_eye_y: float = basket_rig.position.y - 78.0
	var rope_path := PackedVector2Array([
		Vector2(690, 665), Vector2(1028, 119), Vector2(1030, 98),
		Vector2(1042, 79), Vector2(1060, 72), Vector2(1080, 79),
		Vector2(1093, 99), Vector2(1095, 119)
	])
	if rethreaded:
		var wheel_y: float = basket_rig.position.y - 138.0
		rope_path.append_array(PackedVector2Array([
			Vector2(1065, wheel_y - 5.0),
			Vector2(1066, wheel_y + 18.0), Vector2(1080, wheel_y + 34.0),
			Vector2(1100, wheel_y + 39.0), Vector2(1120, wheel_y + 34.0),
			Vector2(1135, wheel_y + 18.0), Vector2(1135, wheel_y - 5.0),
			Vector2(1160, 94)
		]))
	elif rigging_step > 0:
		# With the basket on its dock, the old direct end hangs free while the guide carries the new rope.
		rope_path.append(Vector2(1030, 550))
	else:
		rope_path.append(Vector2(BASKET_X, basket_eye_y))
	rope_shadow.points = rope_path
	rope_core.points = rope_path
	rope_mark_near.visible = rethreaded
	rope_mark_far.visible = rethreaded
	var working_run_start := Vector2(690, 665)
	var working_run_end := Vector2(1028, 119)
	rope_mark_near.position = working_run_start.lerp(working_run_end, clampf(0.20 + basket_progress * 0.65, 0.0, 0.94))
	rope_mark_far.position = working_run_start.lerp(working_run_end, clampf(0.48 + basket_progress * 0.65, 0.0, 0.97))
	moving_pulley.position = Vector2(BASKET_X, basket_rig.position.y - 138.0)
	moving_pulley.visible = trip_complete
	pulley_cover.position = moving_pulley.position
	pulley_cover.visible = trip_complete and not rethreaded and rigging_step == 0
	pilot_guide.visible = trip_complete and not rethreaded
	if rigging_step == 1:
		pilot_guide.points = PackedVector2Array([Vector2(700, 650), Vector2(1015, 126), Vector2(1060, 76), Vector2(1070, moving_pulley.position.y)])
	elif rigging_step == 2:
		pilot_guide.points = PackedVector2Array([Vector2(700, 650), Vector2(1015, 126), Vector2(1060, 76), Vector2(1070, moving_pulley.position.y), Vector2(1100, moving_pulley.position.y + 39), Vector2(1135, moving_pulley.position.y), Vector2(1160, 94)])
	else:
		pilot_guide.points = PackedVector2Array([Vector2(700, 650), Vector2(1015, 126), Vector2(1060, 76), Vector2(1070, moving_pulley.position.y), Vector2(1100, moving_pulley.position.y + 39), Vector2(1135, moving_pulley.position.y), Vector2(1160, 94)])
	pilot_guide.width = 5.0 if rigging_step > 0 else 2.0
	rope_coil.visible = not state.flags.get("shaft_long_rope_taken", false)
	lower_dock_clamp.color = Color("91b3a5") if state.flags.get("shaft_lower_dock_locked", false) else Color("b97d45")
	lower_dock_clamp.rotation = -0.32 if state.flags.get("shaft_lower_dock_locked", false) else 0.0
	var loaded: bool = state.flags.get("shaft_tools_loaded", false)
	var rail_removed: bool = state.flags.get("shaft_rail_removed", false)
	platform_tools.visible = not loaded
	basket_tools.visible = loaded and not rail_removed
	receiving_rail.visible = not rail_removed
	receiving_rail_open.visible = rail_removed
	bent_rail.visible = not rail_removed
	open_rail.visible = rail_removed
	load_indicator.rotation = -0.58 if rethreaded else (-0.12 if loaded and not rail_removed else -0.45)


func _start_rigging() -> void:
	rigging_step = 0
	_set_mode(&"rigging")
	ui.show_shaft_rigging(rigging_step)
	_update_rig_visuals()


func _advance_rigging() -> void:
	rigging_step += 1
	if rigging_step < 3:
		ui.update_shaft_rigging(rigging_step)
		_update_rig_visuals()
		return
	state.flags["shaft_passenger_rethread_complete"] = true
	state.add_note_once(&"shaft-passenger-rope", "A second rope path", "With the empty basket locked to the lower dock, I used the pilot line to draw a long rope through the basket wheel and fixed wheel, then secured its end at the top anchor. Two rope runs now support the basket.")
	sound_player.play()
	wick.react_to(1160.0, 94.0)
	rigging_step = 0
	_update_rig_visuals()
	_start_dialogue(["Wick lights the top latch. Erin checks from her ledge: the rope is seated in both wheels and the anchor is closed.", "The basket is still on its lower clamp. I should release it and test the new path without a passenger."], &"", erin.global_position)


func _start_dialogue(lines: Array[String], completion_action: StringName = &"", speaker: Vector2 = Vector2.ZERO) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_speaker = kath.global_position if speaker == Vector2.ZERO else speaker
	dialogue_beside_erin = speaker != Vector2.ZERO
	pending_dialogue_action = completion_action
	_set_mode(&"dialogue")
	ui.show_dialogue(dialogue_lines[0], dialogue_speaker, dialogue_beside_erin)


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		ui.show_dialogue(dialogue_lines[dialogue_index], dialogue_speaker, dialogue_beside_erin)
		return
	var action := pending_dialogue_action
	_close_overlay()
	_complete_dialogue_action(action)


func _complete_dialogue_action(action: StringName) -> void:
	match action:
		&"contact_erin":
			state.flags["shaft_erin_contacted"] = true
			state.add_note_once(&"shaft-erin-rail", "Erin's landing", "Erin is safe on the fixed upper ledge, but a bent rail blocks the basket entrance. She needs tools to remove it.")
		&"inspect_rig":
			state.flags["shaft_rig_inspected"] = true
			state.add_note_once(&"shaft-direct-rope", "The first rope path", "The basket hangs from a single cable over a fixed pulley to the hand winch. The automatic drive is still; the crank can move the basket.")
		&"load_tools":
			_start_tool_transfer()
			return
		&"clear_rail":
			state.flags["shaft_rail_removed"] = true
			erin.set_repairing(false)
			sound_player.play()
			_update_rig_visuals()
			ui.show_hint("Lower the empty basket to the berth.", 5.0)
		&"finish_tool_trip":
			state.flags["shaft_tool_trip_complete"] = true
			state.add_note_once(&"shaft-tool-trip", "Tools delivered", "The hand winch lifted the tool chest to Erin. She removed the bent rail and returned the empty basket. Its present rope path has not been checked for carrying a person.")
			ui.show_hint("The next step is to inspect the basket's second pulley.", 5.0)
			_update_rig_visuals()
		&"inspect_passenger_rig":
			state.flags["shaft_passenger_rig_inspected"] = true
			state.add_note_once(&"shaft-spare-pulley", "Spare basket wheel", "A covered wheel is bolted above the basket. A thin pilot line leads through it toward the fixed wheel; Kath can use it from the safe platform.")
		&"inspect_top_anchor":
			state.flags["shaft_top_anchor_inspected"] = true
			state.add_note_once(&"shaft-top-anchor", "Top anchor", "A separate top anchor has a pull-operated latch. Erin can confirm it closes from her upper ledge.")
		&"take_long_rope":
			state.flags["shaft_long_rope_taken"] = true
			state.add_note_once(&"shaft-long-rope", "Long maintenance rope", "The rope cabinet holds a longer cable for the alternate basket arrangement.")
			_update_rig_visuals()
		&"lock_lower_dock":
			state.flags["shaft_lower_dock_locked"] = true
			sound_player.play()
			_update_rig_visuals()
		&"release_lower_dock":
			state.flags["shaft_lower_dock_locked"] = false
			sound_player.play()
			_update_rig_visuals()
			ui.show_hint("At the winch, raise the empty basket a little, stop, then bring it back.", 5.0)
	if action in [&"contact_erin", &"inspect_rig"] and state.flags.get("shaft_erin_contacted", false) and state.flags.get("shaft_rig_inspected", false) and not state.flags.get("shaft_tool_goal", false):
		state.flags["shaft_tool_goal"] = true
		_start_dialogue([
			"The bent rail is the first obstacle. The fixed pulley lets this winch move the basket across the shaft.",
			"I can load Erin's tools from the safe platform, then lift the basket to her landing."
		])


func _start_tool_transfer() -> void:
	_set_mode(&"loading")
	ui.hide_modals()
	platform_tools.visible = false
	transfer_tools.position = Vector2(770, 746)
	transfer_tools.visible = true
	sound_player.play()
	var transfer := create_tween()
	transfer.tween_property(loading_spur, "scale:x", 0.16, 0.3)
	transfer.tween_property(transfer_tools, "position", Vector2(1075, 747), 1.35).set_trans(Tween.TRANS_SINE)
	transfer.tween_property(loading_spur, "scale:x", 0.11, 0.3)
	await transfer.finished
	transfer_tools.visible = false
	state.flags["shaft_tools_loaded"] = true
	_update_rig_visuals()
	_set_mode(&"roam")
	ui.show_hint("The tools are secured. E at the winch, then hold Up to lift.", 5.0)


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
	erin.set_repairing(false)
	pending_dialogue_action = &""
	if mode == &"rigging":
		rigging_step = 0
		_update_rig_visuals()
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	if mode != &"winch":
		brake_lever.rotation = 0.0
		winch_motion_direction = 0.0
	kath.controls_enabled = mode == &"roam"
