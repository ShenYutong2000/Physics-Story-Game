extends Node2D
## Fixed engine core: trace the failed home stop, repair it, and return the wing slowly.

const SHAFT_SCENE := "res://scenes/chapter1_maintenance_shaft.tscn"
const OBSERVATORY_SCENE := "res://scenes/chapter1_observatory.tscn"
const STOP_TEXTURE: Texture2D = preload("res://chapter1-assets/engine-room-layers-v1/stop-signal.png")
const NORMAL_TEXTURE: Texture2D = preload("res://chapter1-assets/engine-room-layers-v1/normal-signal.png")
const CLICK_SOUND: AudioStream = preload("res://prologue-asset-pack-v1/audio/lever-click.wav")
const FLOOR_Y := 725.0
const RETURN_RATE := 0.085
const CHECK_IDS := [&"stop", &"brake", &"lock"]
const CHECK_TITLES := ["HOME STOP SIGNAL", "BRAKE PAWL", "NORMAL-POSITION LOCK"]
const OBSERVATION_FLAGS := ["engine_chart_seen", "engine_jam_seen", "engine_linkage_seen", "engine_brake_seen", "engine_signal_seen"]

@onready var state: Node = get_node("/root/PrologueState")
@onready var kath: CharacterBody2D = $Kath
@onready var wick: Node2D = $Wick
@onready var erin: Node2D = $Erin
@onready var ui: CanvasLayer = $HallUI
@onready var window_wing_pivot: Node2D = $WindowWingPivot
@onready var normal_linkage: Sprite2D = $NormalLinkage
@onready var backup_lock: Sprite2D = $BackupLock
@onready var brake_wheel: Sprite2D = $BrakeWheel
@onready var brake_pawl: Sprite2D = $BrakePawl
@onready var stop_signal: Sprite2D = $StopSignal
@onready var jam_debris: Sprite2D = $JamDebris
@onready var drive_isolator_lamp: Polygon2D = $DriveIsolatorLamp
@onready var shaft_return: Node2D = $ShaftReturn
@onready var wall_chart: Node2D = $WallChart
@onready var isolator: Node2D = $Isolator
@onready var erin_conversation: Node2D = $ErinConversation
@onready var obstruction: Node2D = $Obstruction
@onready var linkage: Node2D = $Linkage
@onready var brake_assembly: Node2D = $BrakeAssembly
@onready var maintenance_drive: Node2D = $MaintenanceDrive
@onready var stop_indicator: Node2D = $StopIndicator
@onready var observatory_exit: Node2D = $ObservatoryExit
@onready var hotspots: Array[Node] = [shaft_return, wall_chart, isolator, erin_conversation, obstruction, linkage, brake_assembly, maintenance_drive, stop_indicator, observatory_exit]

var mode: StringName = &"roam"
var dialogue_lines: Array[String] = []
var dialogue_index := 0
var dialogue_speaker := Vector2.ZERO
var pending_action: StringName = &""
var check_selection := 0
var hypothesis_selection := -1
var repair_selection := -1
var pending_checks: Array[StringName] = []
var return_progress := 0.0
var sound_player: AudioStreamPlayer


func _ready() -> void:
	var spawn_tag: StringName = state.take_spawn_tag()
	ui.hint.position = Vector2(36, 45)
	ui.hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	kath.floor_y = FLOOR_Y
	kath.left_limit = 115.0
	kath.right_limit = 1555.0
	kath.position = Vector2(1450.0 if spawn_tag == &"from-observatory" else 265.0, FLOOR_Y)
	return_progress = clampf(float(state.flags.get("engine_return_progress", 0.0)), 0.0, 1.0)
	sound_player = AudioStreamPlayer.new()
	get_node("/root/GameSettings").configure_audio(sound_player)
	sound_player.stream = CLICK_SOUND
	sound_player.volume_db = -14.0
	add_child(sound_player)
	_refresh_art()
	if spawn_tag == &"from-maintenance-shaft" and not state.flags.get("engine_intro_seen", false):
		state.flags["engine_intro_seen"] = true
		_start_dialogue(["Erin: This fixed core houses the Castle's ring drive. Its overload tripped when the inverted catch held the wing, but the feed is still connected.", "Kath: The Archive's drive was already off. Let's inspect this separate home stop before touching the Castle's isolator."], &"", erin.global_position)
	elif state.castle_pose == &"restored":
		ui.show_hint("The wing is secured at home. The observatory passage is open.", 5.0)
	elif state.flags.get("engine_checks_verified", false):
		ui.show_hint("Use the maintenance drive to bring the wing slowly home.", 5.0)
	elif state.flags.get("engine_jam_cleared", false):
		ui.show_hint("Test the home linkage before moving the wing.", 5.0)


func _process(delta: float) -> void:
	if mode == &"drive":
		_process_return_drive(delta)
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
	if closest == shaft_return:
		action = "RETURN"
	elif closest == erin_conversation:
		action = "REVIEW" if state.flags.get("chapter1_complete", false) else "TELL"
	elif closest == observatory_exit:
		action = "ENTER" if state.castle_pose == &"restored" else "WAIT"
	elif closest == isolator and state.flags.get("engine_fault_traced", false) and not state.flags.get("engine_drive_isolated", false):
		action = "ISOLATE"
	elif closest == obstruction and state.flags.get("engine_drive_isolated", false) and not state.flags.get("engine_jam_cleared", false):
		action = "CLEAR"
	elif closest == linkage and state.flags.get("engine_jam_cleared", false) and not state.flags.get("engine_checks_verified", false):
		action = "TEST"
	elif closest == maintenance_drive and state.flags.get("engine_checks_verified", false) and state.castle_pose != &"restored":
		action = "OPERATE"
	elif closest == wall_chart and _observations_complete() and not state.flags.get("engine_fault_traced", false):
		action = "COMPARE CLUES"
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
	elif mode == &"dialogue" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_advance_dialogue()
	elif mode == &"hypothesis":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			get_viewport().set_input_as_handled()
			hypothesis_selection = 0 if event.is_action_pressed("move_left") else 1
			_update_hypothesis()
		elif event.is_action_pressed("advance_dialogue"):
			get_viewport().set_input_as_handled()
			if hypothesis_selection < 0:
				_update_hypothesis()
			elif hypothesis_selection == 0:
				repair_selection = -1
				_set_mode(&"repair_order")
				_update_repair_order()
			else:
				_close_overlay()
				_start_dialogue(["A failed signal alone would not keep the mechanical brake pawl out of its seat. The jammed rod can explain both the dark signal and the missed brake.", "I should compare the linkage and brake again before choosing a repair sequence."])
	elif mode == &"repair_order":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			get_viewport().set_input_as_handled()
			repair_selection = 0 if event.is_action_pressed("move_left") else 1
			_update_repair_order()
		elif event.is_action_pressed("advance_dialogue"):
			get_viewport().set_input_as_handled()
			if repair_selection < 0:
				_update_repair_order()
			elif repair_selection == 0:
				_close_overlay()
				_confirm_fault_chain()
			else:
				_close_overlay()
				_start_dialogue(["That order would put my hands beside a rod that the live drive can still move. Isolate the drive first, then clear and test the stop path."])
	elif mode == &"verification":
		if event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
			get_viewport().set_input_as_handled()
			check_selection = posmod(check_selection + (-1 if event.is_action_pressed("move_left") else 1), 3)
			_update_check_panel()
		elif event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			var check_id: StringName = CHECK_IDS[check_selection]
			if not pending_checks.has(check_id):
				pending_checks.append(check_id)
				sound_player.play()
			_update_check_panel()
		elif event.is_action_pressed("advance_dialogue"):
			get_viewport().set_input_as_handled()
			if pending_checks.size() == CHECK_IDS.size():
				_complete_verification()
			else:
				ui.update_engine_maintenance(_check_status() + "\n\nCheck all three before moving the wing.")
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
	elif mode == &"chapter_end" and event.is_action_pressed("advance_dialogue"):
		get_viewport().set_input_as_handled()
		_close_overlay()


func nearest_hotspot(feet_x: float) -> Node:
	var best: Node = null
	var best_distance := INF
	for hotspot in hotspots:
		if hotspot == erin_conversation and not state.flags.get("observatory_page_stitched", false):
			continue
		if not hotspot.is_reachable(feet_x):
			continue
		var distance: float = hotspot.distance_from(feet_x)
		if distance < best_distance:
			best = hotspot
			best_distance = distance
	return best


func _inspect(hotspot: Node) -> void:
	if hotspot == shaft_return:
		_set_mode(&"travel")
		ui.hide_modals()
		state.travel_to(SHAFT_SCENE, &"from-engine-room")
	elif hotspot == observatory_exit:
		if state.castle_pose != &"restored":
			_start_dialogue(["The rotating passage is out of line. I cannot cross until the wing is back at its normal position and locked."])
		else:
			_set_mode(&"travel")
			ui.hide_modals()
			state.travel_to(OBSERVATORY_SCENE, &"from-engine-room")
	elif hotspot == erin_conversation:
		if state.flags.get("chapter1_complete", false):
			_set_mode(&"chapter_end")
			ui.show_chapter1_end()
		elif state.flags.get("observatory_page_stitched", false) and state.flags.get("observatory_archive_complete", false) and state.castle_pose == &"restored":
			_start_dialogue(["Kath: The castle record has both our names. The Floating Isles station was waiting for a comparison from us.", "Erin: I'll keep this castle running and try to restore the station link. Follow the unfinished comparison.", "Kath: If one page could help us, imagine what the rest might hold."], &"finish_chapter", erin.global_position)
	elif hotspot == wall_chart:
		if _observations_complete() and not state.flags.get("engine_fault_traced", false):
			hypothesis_selection = -1
			_set_mode(&"hypothesis")
			_update_hypothesis()
		else:
			_start_dialogue(["This chart keeps the central tower fixed while one observatory wing turns in its ring.", "The Archive line supplies an auxiliary signal, not the Castle ring motor. Its local home rod trips the signal and brake; an inverted catch is separate."], &"observe_chart")
	elif hotspot == obstruction:
		if state.flags.get("engine_jam_cleared", false):
			_start_dialogue(["The travel slot is clear. There are still damp marks where the broken seal let water and grit collect."])
		elif state.flags.get("engine_drive_isolated", false):
			_start_dialogue(["Erin braces the isolated linkage. I can pull the wet grit out of its track without the drive moving it."], &"clear_jam", erin.global_position)
		else:
			_start_dialogue(["Wet grit and a loose fragment wedge the normal-position rod.", "The roof leak may have fed this path, but we have not traced its source. Isolate the drive before touching it."], &"observe_jam")
	elif hotspot == linkage:
		if state.flags.get("engine_jam_cleared", false) and not state.flags.get("engine_checks_verified", false):
			_start_verification()
		elif state.flags.get("engine_checks_verified", false):
			_start_dialogue(["The handwheel moved the cleared rod. The stop, brake and home lock each responded in the isolated dry run."])
		else:
			_start_dialogue(["This rod should travel when the wing reaches home. Its end is stuck short of the position that trips the stop and brake."], &"observe_linkage")
	elif hotspot == brake_assembly:
		_start_dialogue(["The home rod is stuck, so the normal brake pawl cannot reach its seat.", "A separate bolt holds the wing at the inverted maintenance mark. It stopped the wing here."], &"observe_brake")
	elif hotspot == stop_indicator:
		_start_dialogue(["The home signal stayed dark as the wing passed level. The ring-drive lamp remained lit after Kath released the test lever.", "At the inverted catch the motor fell silent and the overload tripped. The Castle feed is still connected; the Archive drive was already off."], &"observe_signal")
	elif hotspot == isolator:
		if state.flags.get("engine_drive_isolated", false):
			_start_dialogue(["The ring-drive feed lamp is dark: the automatic circuit is isolated. The separate maintenance drive can be used only after the stop path is tested."])
		elif state.flags.get("engine_fault_traced", false):
			_start_dialogue(["Erin: The overload stopped the motor, but that is not a safe isolator. I'll disconnect the automatic ring drive before we clear the jammed rod."], &"isolate_drive", erin.global_position)
		else:
			_start_dialogue(["The red feed lamp shows the automatic ring-drive circuit remains connected. First I should trace the rod, signal, brake and backup catch; then isolate it before touching the track."])
	elif hotspot == maintenance_drive:
		if state.castle_pose == &"restored":
			_start_dialogue(["The dial reads home. The brake and normal lock hold the wing; the maintenance drive is stopped."])
		elif not state.flags.get("engine_checks_verified", false):
			_start_dialogue(["I will not move the wing until the blockage is cleared and the home stop, brake and lock pass a dry run."])
		else:
			_open_drive()


func _start_dialogue(lines: Array[String], action: StringName = &"", speaker: Vector2 = Vector2.ZERO) -> void:
	dialogue_lines = lines
	dialogue_index = 0
	dialogue_speaker = kath.global_position if speaker == Vector2.ZERO else speaker
	pending_action = action
	_set_mode(&"dialogue")
	_show_dialogue_line()


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index < dialogue_lines.size():
		_show_dialogue_line()
		return
	var action := pending_action
	_close_overlay()
	_complete_dialogue_action(action)


func _show_dialogue_line() -> void:
	var line: String = dialogue_lines[dialogue_index]
	var speaker_position := dialogue_speaker
	if line.begins_with("Kath:"):
		speaker_position = kath.global_position
	elif line.begins_with("Erin:"):
		speaker_position = erin.global_position
	ui.show_dialogue(line, speaker_position)


func _complete_dialogue_action(action: StringName) -> void:
	match action:
		&"observe_chart":
			state.flags["engine_chart_seen"] = true
			state.add_note_once(&"engine-orientation-chart", "Two drives, one rotating wing", "The tower and service core are fixed. The Castle's own ring motor turns the observatory wing; the Archive line is an auxiliary signal and drive, not its sole power. The normal home stop and inverted catch are separate.")
		&"observe_jam":
			state.flags["engine_jam_seen"] = true
			state.add_note_once(&"engine-jammed-track", "Wet track", "Water marks, grit and a loose fragment are wedged in the normal-position linkage. The route by which the water arrived is not confirmed.")
		&"observe_linkage":
			state.flags["engine_linkage_seen"] = true
		&"observe_brake":
			state.flags["engine_brake_seen"] = true
		&"observe_signal":
			state.flags["engine_signal_seen"] = true
			state.add_note_once(&"engine-feed-evidence", "Castle drive evidence", "The Archive drive was stopped before arrival. During the Castle's return test, its ring-drive lamp stayed lit after the selector was released and the home signal stayed dark. At the inverted catch, the motor fell silent, but the feed isolator remained connected. The two controls are distinct.")
		&"isolate_drive":
			if state.flags.get("engine_fault_traced", false):
				state.flags["engine_drive_isolated"] = true
				sound_player.play()
				_refresh_art()
				ui.show_hint("Automatic drive isolated. Clear the blocked track.", 5.0)
		&"clear_jam":
			if state.flags.get("engine_drive_isolated", false):
				state.flags["engine_jam_cleared"] = true
				state.add_note_once(&"engine-track-cleared", "Linkage cleared", "With the automatic drive isolated and Erin bracing the assembly, I removed wet grit and a loose metal fragment from the home rod's track.")
				sound_player.play()
				wick.react_to(880.0, 520.0)
				_refresh_art()
				ui.show_hint("At the home linkage, test the stop path before moving the wing.", 5.0)
		&"finish_chapter":
			if state.flags.get("observatory_page_stitched", false) and state.flags.get("observatory_archive_complete", false) and state.castle_pose == &"restored":
				state.flags["chapter1_complete"] = true
				state.add_note_once(&"chapter1-departure", "Toward the Floating Isles", "Kath and Erin confirmed their shared Grand Archive work record. Erin stayed to maintain the restored castle and try the station link; Kath left with the repaired notebook to seek the Floating Isles comparison results. The reason for the withdrawn records remains unknown.")
				wick.react_to(1510.0, 240.0)
				_set_mode(&"chapter_end")
				ui.show_chapter1_end()
	if action in [&"observe_chart", &"observe_jam", &"observe_linkage", &"observe_brake", &"observe_signal"]:
		_maybe_trace_fault()


func _maybe_trace_fault() -> void:
	if state.flags.get("engine_fault_traced", false):
		return
	if not _observations_complete():
		return
	if not state.flags.get("engine_compare_prompt_seen", false):
		state.flags["engine_compare_prompt_seen"] = true
		ui.show_hint("The marks form a sequence. Compare them at the wall chart.", 6.0)


func _observations_complete() -> bool:
	for flag in OBSERVATION_FLAGS:
		if not state.flags.get(flag, false):
			return false
	return true


func _update_hypothesis() -> void:
	var selected := "Choose with ← / →" if hypothesis_selection < 0 else "A selected" if hypothesis_selection == 0 else "B selected"
	ui.show_engine_maintenance("TRACE THE HOME STOP", "The Castle motor ran after the selector was released. The home rod is jammed, its signal stayed dark, and the brake missed its seat. Which order fits?", "← A  Rod jams → signal/brake miss → catch holds\n→ B  Signal fails → rod jams → brake misses\n\n%s" % selected, "← / → CHOOSE   ·   ENTER TEST   ·   ESC CANCEL")


func _update_repair_order() -> void:
	var selected := "Choose with ← / →" if repair_selection < 0 else "A selected" if repair_selection == 0 else "B selected"
	ui.show_engine_maintenance("PLAN A SAFE REPAIR", "The inverted catch currently holds the wing. The automatic drive is still connected, and the normal stop rod is jammed. What should we do first?", "← A  Isolate → clear → dry-run test → return\n→ B  Clear → return → test → isolate\n\n%s" % selected, "← / → CHOOSE   ·   ENTER CONFIRM   ·   ESC CANCEL")


func _confirm_fault_chain() -> void:
	state.flags["engine_fault_traced"] = true
	state.add_note_once(&"engine-fault-chain", "Missed home stop", "The jammed home rod explains why the signal and brake missed the home position while the Castle's ring drive kept turning. The inverted catch held the wing and tripped the motor overload. This is the best explanation for this test, not proof of where the water entered. We chose to isolate, clear and dry-run the stop path before returning the wing.")
	_start_dialogue(["Kath: The jammed rod explains the dark home signal and the missed brake. The Archive shutdown did not stop this Castle motor.", "Erin: The inverted catch and overload held it here. Isolate the ring drive, clear the track, then test the stop path before a slow return."], &"", erin.global_position)


func _start_verification() -> void:
	pending_checks.clear()
	check_selection = 0
	_set_mode(&"verification")
	ui.show_engine_maintenance("HOME LINKAGE · ISOLATED DRY RUN", "Erin turns the handwheel through its normal-position travel while the automatic drive is isolated. Check each response before a powered return.", _check_status(), "← / → SELECT   ·   E CHECK   ·   ENTER CONFIRM   ·   ESC CANCEL")


func _check_status() -> String:
	var lines: Array[String] = []
	for index in CHECK_IDS.size():
		lines.append("%s  %s  %s" % ["›" if index == check_selection else " ", "✓" if pending_checks.has(CHECK_IDS[index]) else "○", CHECK_TITLES[index]])
	return "\n".join(lines)


func _update_check_panel() -> void:
	ui.update_engine_maintenance(_check_status() + "\n\n" + ["The signal contact closes at the home mark.", "The brake pawl reaches its seat when the rod moves.", "The normal lock can slide into its home socket; it is not engaged while inverted."][check_selection])


func _complete_verification() -> void:
	if not state.flags.get("engine_jam_cleared", false) or pending_checks.size() != CHECK_IDS.size():
		return
	state.flags["engine_checks_verified"] = true
	state.add_note_once(&"engine-home-stop-test", "Home stop dry run", "With the wing still held inverted and the automatic drive isolated, Erin moved the cleared linkage by hand. The home signal closed, the brake pawl travelled, and the normal lock reached its socket in a dry run. None of them is holding the wing at home yet.")
	sound_player.play()
	_close_overlay()
	_refresh_art()
	_start_dialogue(["Erin: The signal, brake and normal lock each moved in the isolated test.", "Erin: The inverted catch still holds the wing. Use the maintenance drive slowly; release it to stop.", "Kath: I'll watch the angle until the home lock engages."], &"", erin.global_position)


func _open_drive() -> void:
	_set_mode(&"drive")
	_update_drive_panel(true)


func _update_drive_panel(first: bool = false) -> void:
	var angle := 180.0 * (1.0 - return_progress)
	var status := "Wing angle from home: %d°\nReturn completed: %d%%\n%s" % [roundi(angle), roundi(return_progress * 100.0), "The maintenance drive is turning slowly toward home." if Input.is_action_pressed("move_left") else "The brake holds when the key is released."]
	if first:
		ui.show_engine_maintenance("SLOW RETURN · MAINTENANCE DRIVE", "The normal stop path passed its dry run. The automatic circuit remains isolated; this local drive moves only while held.", status, "HOLD ← TO RETURN   ·   RELEASE TO BRAKE   ·   ESC CLOSE")
	else:
		ui.update_engine_maintenance(status)


func _process_return_drive(delta: float) -> void:
	if state.castle_pose == &"restored":
		return
	if Input.is_action_pressed("move_left"):
		return_progress = minf(1.0, return_progress + minf(delta, 0.1) * RETURN_RATE)
		state.flags["engine_return_progress"] = return_progress
		_refresh_art()
	_update_drive_panel()
	if return_progress >= 0.999:
		_complete_restoration()


func _complete_restoration() -> void:
	if state.castle_pose == &"restored":
		return
	if not state.flags.get("engine_checks_verified", false) or return_progress < 0.999:
		return
	if not state.transition_castle_pose(&"restored"):
		return
	return_progress = 1.0
	state.flags["engine_return_progress"] = 1.0
	state.flags["engine_restored"] = true
	state.add_note_once(&"engine-wing-restored", "Wing returned to home", "With the automatic ring drive isolated, the cleared stop path passed a dry run. The separate maintenance drive returned the wing slowly; at home, the signal changed, brake engaged and normal lock seated. This return worked under today's load and speed. The water's route and long-term reliability still need checking.")
	sound_player.play()
	_refresh_art()
	_start_dialogue(["The dial reaches home. The signal changes, the brake catches, and the normal lock seats.", "The wing stays still when Kath releases the drive.", "Erin: The observatory passage lines up again. We should check its work records next."])


func _refresh_art() -> void:
	if window_wing_pivot == null:
		return
	var restored: bool = state.castle_pose == &"restored"
	var cleared: bool = state.flags.get("engine_jam_cleared", false)
	var verified: bool = state.flags.get("engine_checks_verified", false)
	var progress: float = 1.0 if restored else return_progress
	window_wing_pivot.rotation = lerpf(state.castle_pose_angle_radians(&"inverted"), state.castle_pose_angle_radians(&"restored"), progress)
	jam_debris.visible = not cleared and not restored
	drive_isolator_lamp.color = Color("526b69") if state.flags.get("engine_drive_isolated", false) or restored else Color("e97d4a")
	normal_linkage.position = Vector2(852.0 + (25.0 if restored else 12.0 if cleared else 0.0), 460.0)
	backup_lock.position.y = 250.0 if restored or progress > 0.01 else 310.0
	brake_wheel.modulate = Color.WHITE if verified or restored else Color(0.72, 0.74, 0.82, 1.0)
	brake_pawl.visible = restored
	stop_signal.texture = NORMAL_TEXTURE if restored else STOP_TEXTURE


func _show_journal() -> void:
	ui.show_journal(state.notes, state.hall_checks_complete(), bool(state.flags.get("machine_baseline_recorded", false)), bool(state.flags.get("stacks_bucket_moved", false)), bool(state.flags.get("stacks_page_collected", false)), bool(state.flags.get("room_notebook_compared", false)), bool(state.flags.get("incident_complete", false)), state.room_preparation_complete(), bool(state.flags.get("machine_incident_active", false)), bool(state.flags.get("service_gate_open", false)), bool(state.flags.get("service_road_end_reached", false)))


func _close_overlay() -> void:
	if mode == &"verification":
		pending_checks.clear()
	ui.hide_modals()
	pending_action = &""
	_set_mode(&"roam")


func _set_mode(value: StringName) -> void:
	mode = value
	kath.controls_enabled = mode == &"roam"
